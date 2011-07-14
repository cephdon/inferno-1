implement Fsmodule;
include "sys.m";
	sys: Sys;
include "readdir.m";
	readdir: Readdir;
include "bufio.m";
	bufio: Bufio;
	Iobuf: import bufio;
include "string.m";
	str: String;
include "draw.m";
include "sh.m";
include "fslib.m";
	fslib: Fslib;
	Report, Value, type2s, report, quit: import fslib;
	Fschan, Fsdata, Entrychan, Entry,
	Gatechan, Gatequery, Nilentry, Option,
	Next, Down, Skip, Quit: import Fslib;

File: adt {
	name: string;
	mode: int;
	owner: string;
	group: string;
	old: string;
	flags: int;
	sub: cyclic array of ref File;
};

Proto: adt {
	indent: int;
	lastline: string;
	iob: ref Iobuf;
};

Star, Plus: con 1<<iota;

types(): string
{
	return "ts-rs";
}

badmod(p: string)
{
	sys->fprint(sys->fildes(2), "fs: eproto: cannot load %s: %r\n", p);
	raise "fail:bad module";
}

init()
{
	sys = load Sys Sys->PATH;
	fslib = load Fslib Fslib->PATH;
	if(fslib == nil)
		badmod(Fslib->PATH);
	readdir = load Readdir Readdir->PATH;
	if(readdir == nil)
		badmod(Readdir->PATH);
	bufio = load Bufio Bufio->PATH;
	if(bufio == nil)
		badmod(Bufio->PATH);
	str = load String String->PATH;
	if(str == nil)
		badmod(String->PATH);
}

run(nil: ref Draw->Context, report: ref Report,
			opts: list of Option, args: list of ref Value): ref Value
{
	protofile := (hd args).s().i;
	rootpath: string;
	if(opts != nil)
		rootpath = (hd (hd opts).args).s().i;
	if(rootpath == nil)
		rootpath = "/";

	proto := ref Proto(0, nil, nil);
	if((proto.iob = bufio->open(protofile, Sys->OREAD)) == nil){
		sys->fprint(sys->fildes(2), "fs: eproto: cannot open %q: %r\n", protofile);
		return nil;
	}
	root := ref File(rootpath, ~0, nil, nil, nil, 0, nil);
	(root.flags, root.sub) = readproto(proto, -1);
	c := Entrychan(chan of int, chan of Entry);
	spawn protowalk(c, root, report.start("proto"));
	return ref Value.T(c);
}

protowalk(c: Entrychan, root: ref File, errorc: chan of string)
{
	if(<-c.sync == 0){
		quit(errorc);
		exit;
	}
	protowalk1(c, root.flags, root.name, file2dir(root, nil), root.sub, -1, errorc);
	c.c <-= (nil, nil, 0);
	quit(errorc);
}

protowalk1(c: Entrychan, flags: int, path: string, d: ref Sys->Dir,
		sub: array of ref File, depth: int, errorc: chan of string): int
{
	if(depth >= 0)
		c.c <-= (d, path, depth);
	depth++;
	(a, n) := readdir->init(path, Readdir->NAME|Readdir->COMPACT);
	j := 0;
	prevsub: string;
	for(i := 0; i < n; i++){
		for(; j < len sub; j++){
			s := sub[j].name;
			if(s == prevsub){
				report(errorc, sys->sprint("duplicate entry %s", pathconcat(path, s)));
				continue;			# eliminate duplicates in proto
			}
			if(s >= a[i].name || sub[j].old != nil)
				break;
			report(errorc, sys->sprint("%s not found", pathconcat(path, s)));
		}
		foundsub := j < len sub && (sub[j].name == a[i].name || sub[j].old != nil);
		if(foundsub || flags&Plus ||
				(flags&Star && (a[i].mode & Sys->DMDIR)==0)){
			f: ref File;
			if(foundsub){
				f = sub[j++];
				prevsub = f.name;
			}
			p: string;
			d: ref Sys->Dir;
			if(foundsub && f.old != nil){
				p = f.old;
				(ok, xd) := sys->stat(p);
				if(ok == -1){
					report(errorc, sys->sprint("cannot stat %q: %r", p));
					continue;
				}
				d = ref xd;
			}else{
				p = pathconcat(path, a[i].name);
				d = a[i];
			}

			d = file2dir(f, d);
			r: int;
			if((d.mode & Sys->DMDIR) == 0)
				r = walkfile(c, p, d, depth, errorc);
			else if(flags & Plus)
				r = protowalk1(c, Plus, p, d, nil, depth, errorc);
			else
				r = protowalk1(c, f.flags, p, d, f.sub, depth, errorc);
			if(r == Skip)
				return Next;
		}
	}
	return Next;
}

pathconcat(p, name: string): string
{		
	if(p != nil && p[len p - 1] != '/')
		p[len p] = '/';
	return p+name;
}

# from(ish) walk.b
walkfile(c: Entrychan, path: string, d: ref Sys->Dir, depth: int, errorc: chan of string): int
{
	fd := sys->open(path, Sys->OREAD);
	if(fd == nil)
		report(errorc, sys->sprint("cannot open %q: %r", path));
	else
		c.c <-= (d, path, depth);
	return Next;
}

readproto(proto: ref Proto, indent: int): (int, array of ref File)
{
	a := array[10] of ref File;
	n := 0;
	flags := 0;
	while((f := readline(proto, indent)) != nil){
		if(f.name == "*")
			flags |= Star;
		else if(f.name == "+")
			flags |= Plus;
		else{
			(f.flags, f.sub) = readproto(proto, proto.indent);
			if(n == len a)
				a = (array[n * 2] of ref File)[0:] = a;
			a[n++] = f;
		}
	}
	if(n < len a)
		a = (array[n] of ref File)[0:] = a[0:n];
	mergesort(a, array[n] of ref File);
	return (flags, a);
}

readline(proto: ref Proto, indent: int): ref File
{
	s: string;
	if(proto.lastline != nil){
		s = proto.lastline;
		proto.lastline = nil;
	}else if(proto.indent == -1)
		return nil;
	else if((s = proto.iob.gets('\n')) == nil){
		proto.indent = -1;
		return nil;
	}
	spc := 0;
	for(i := 0; i < len s; i++){
		c := s[i];
		if(c == ' ')
			spc++;
		else if(c == '\t')
			spc += 8;
		else
			break;
	}
	if(i == len s || s[i] == '#' || s[i] == '\n')
		return readline(proto, indent);	# XXX sort out tail recursion!
	if(spc <= indent){
		proto.lastline = s;
		return nil;
	}
	proto.indent = spc;
	(nil, toks) := sys->tokenize(s, " \t\n");
	f := ref File(nil, ~0, nil, nil, nil, 0, nil);
	(f.name, toks) = (getname(hd toks, 0), tl toks);
	if(toks == nil)
		return f;
	(f.mode, toks) = (getmode(hd toks), tl toks);
	if(toks == nil)
		return f;
	(f.owner, toks) = (getname(hd toks, 1), tl toks);
	if(toks == nil)
		return f;
	(f.group, toks) = (getname(hd toks, 1), tl toks);
	if(toks == nil)
		return f;
	(f.old, toks) = (hd toks, tl toks);
	return f;
}

mergesort(a, b: array of ref File)
{
	r := len a;
	if (r > 1) {
		m := (r-1)/2 + 1;
		mergesort(a[0:m], b[0:m]);
		mergesort(a[m:], b[m:]);
		b[0:] = a;
		for ((i, j, k) := (0, m, 0); i < m && j < r; k++) {
			if(b[i].name > b[j].name)
				a[k] = b[j++];
			else
				a[k] = b[i++];
		}
		if (i < m)
			a[k:] = b[i:m];
		else if (j < r)
			a[k:] = b[j:r];
	}
}

getname(s: string, allowminus: int): string
{
	if(s == nil)
		return nil;
	if(allowminus && s == "-")
		return nil;
	if(s[0] == '$'){
		s = getenv(s[1:]);
		if(s == nil)
			;	# TO DO: w.warn(sys->sprint("can't read environment variable %s", s));
		return s;
	}
	return s;
}

getenv(s: string): string
{
	if(s == "user")
		return readfile("/dev/user");	# more accurate?
	return readfile("/env/"+s);
}

readfile(f: string): string
{
	fd := sys->open(f, Sys->OREAD);
	if(fd != nil){
		a := array[256] of byte;
		n := sys->read(fd, a, len a);
		if(n > 0)
			return string a[0:n];
	}
	return nil;
}

getmode(s: string): int
{
	s = getname(s, 1);
	if(s == nil)
		return ~0;
	m := 0;
	i := 0;
	if(s[i] == 'd'){
		m |= Sys->DMDIR;
		i++;
	}
	if(i < len s && s[i] == 'a'){
		m |= Sys->DMAPPEND;
		i++;
	}
	if(i < len s && s[i] == 'l'){
		m |= Sys->DMEXCL;
		i++;
	}
	(xmode, t) := str->toint(s, 8);
	if(t != nil){
		# report(aux.errorc, "bad mode specification %q", s);
		return ~0;
	}
	return xmode | m;
}

file2dir(f: ref File, old: ref Sys->Dir): ref Sys->Dir
{
	d := ref Sys->nulldir;
	if(old != nil){
		if(old.dtype != 'M'){
			d.uid = "sys";
			d.gid = "sys";
			xmode := (old.mode >> 6) & 7;
			d.mode = old.mode | xmode | (xmode << 3);
		}else{
			d.uid = old.uid;
			d.gid = old.gid;
			d.mode = old.mode;
		}
		d.length = old.length;
		d.mtime = old.mtime;
		d.atime = old.atime;
		d.muid = old.muid;
		d.name = old.name;
	}
	if(f != nil){
		d.name = f.name;
		if(f.owner != nil)
			d.uid = f.owner;
		if(f.group != nil)
			d.gid = f.group;
		if(f.mode != ~0)
			d.mode = f.mode;
	}
	return d;
}
