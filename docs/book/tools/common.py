"""Shared helpers: where things are, and how to read sections, test functions and signatures from the sources."""
import re,glob,os,json,difflib
HERE=os.path.dirname(os.path.abspath(__file__))+'/'
ROOT=os.path.normpath(HERE+'../../..')+'/'
BOOK=ROOT+'docs/book/'; SRC=ROOT+'src/main/ridgun/lib/'; TST=ROOT+'src/test/ridgun/'
LANGS=["es","ca","gl","eu","en","pt","sv","it"]
def chapters(lang):
    return sorted(glob.glob(f'{BOOK}{lang}/[0-9]*.md'))
def lib_of(path):
    n=re.search(r'/\d\d-lib-([a-z0-9]+)-',path).group(1)
    return 'net_agent' if n=='net' else n
def src_of(lib): return open(SRC+lib+'.ridgun').read()
def test_path(lib):
    if lib in ('pool','net_agent'): lib='agent'
    for c in (f'test {lib}.ridgun', f'test {lib.replace("_"," ")}.ridgun'):
        if os.path.exists(TST+c): return TST+c
    return None
def clean(text):
    """drop requirement markers, trim blank lines at both ends"""
    ls=[l for l in text.split('\n') if not re.match(r'^\s*-- @\w+',l)]
    while ls and not ls[0].strip(): ls.pop(0)
    while ls and not ls[-1].strip(): ls.pop()
    out=[]
    for l in ls:                       # collapse runs of blank lines left by dropped markers
        if not l.strip() and out and not out[-1].strip(): continue
        out.append(l.rstrip())
    return '\n'.join(out)
def banners(src):
    """[(title, body)]: sections opened by '-- ── Title ──' or by a '-- ====' box, up to the next banner."""
    ls=src.split('\n'); marks=[]; i=0
    while i<len(ls):
        l=ls[i]
        m=re.match(r'^-- ── (.*?)(?: ─+)?\s*$',l)
        if m: marks.append((i,i+1,m.group(1).strip())); i+=1; continue
        if re.match(r'^-- ={20,}\s*$',l):
            j=i+1
            while j<len(ls) and ls[j].startswith('--') and not re.match(r'^-- ={20,}\s*$',ls[j]): j+=1
            if j<len(ls) and j>i+1:
                title=ls[i+1][3:].strip()
                if i>0 and not title.startswith('src/'): marks.append((i,j+1,title))
                i=j+1; continue
        i+=1
    out=[]
    for k,(a,b,t) in enumerate(marks):
        e=marks[k+1][0] if k+1<len(marks) else len(ls)
        out.append((t,'\n'.join(ls[b:e])))
    return out
def fn_range(src,start,end):
    """from the line starting with `start` (plus the comment lines right above it) to the end of the definition starting with `end`"""
    ls=src.split('\n')
    a=next(i for i,l in enumerate(ls) if l.startswith(start))
    while a>0 and ls[a-1].startswith('--') and not re.match(r'^-- (=|──)',ls[a-1]): a-=1
    b=next(i for i,l in enumerate(ls) if i>=a and l.startswith(end))
    j=b+1
    while j<len(ls) and (ls[j].startswith(' ') or not ls[j].strip()): j+=1
    return '\n'.join(ls[a:j])
def test_fns(t):
    ls=t.split('\n'); out={}; order=[]; i=0
    while i<len(ls):
        if re.match(r'^fn :: ',ls[i]):
            j=i+1
            while j<len(ls) and (ls[j].startswith(' ') or ls[j]==''): j+=1
            body=ls[i:j]
            while body and body[-1]=='': body.pop()
            out[ls[i].rstrip()]='\n'.join(body); order.append(ls[i].rstrip()); i=j
        else: i+=1
    return out,order
def catalog(src):
    types=[]; ops=[]; fns=[]
    for l in src.split('\n'):
        if re.match(r'^(expand )?type ',l): types.append(l.rstrip())
        elif l.startswith('op :: '): ops.append(re.sub(r'\s+',' ',l).strip())
        elif (l.startswith('fn :: ') or l.startswith('cpu op :: ')) and '=>' in l:   # a processor operation is listed with the functions
            left,ret=l.split('=>',1)
            fns.append((re.sub(r'\s+',' ',left).strip(),re.sub(r'\s+',' ',ret).strip()))
    return types,ops,fns
