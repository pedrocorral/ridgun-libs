#!/usr/bin/env python3
"""Refresh every chapter of the book from the current sources and tests.

  python3 docs/book/tools/refresh.py     rewrite the chapters and the INDEX.md of each edition
  python3 docs/book/tools/verify.py      check names, examples and code against the sources
  python3 docs/book/build_book.py        rebuild the HTML books

Rebuilt from the code: the catalog of types and signatures, the examples that show a test function,
the "under the hood" sections. Taken from data.py and strings/<lang>.json: new chapters, example titles,
table rows, corrected names. A run on an up-to-date book changes nothing."""
import sys
from common import *
from data import *

EN=json.load(open(HERE+'strings/en.json'))
S={l: json.load(open(HERE+f'strings/{l}.json')) for l in LANGS}
def st(lang,key):
    v=S[lang].get(key)
    if v is None:
        MISSING.add((lang,key)); v=EN[key]
    return v
MISSING=set(); REPORT=[]
LIB_COUNT=len(glob.glob(SRC+'*.ridgun'))
_prev=re.search(r'\(01–(\d+)\)',open(BOOK+'build_book.py').read()).group(1)
OLD_COUNT=r'\b(?:32|34|'+_prev+r')'

def find(ls,pat,start=0,end=None):
    for i in range(start,len(ls) if end is None else end):
        if re.match(pat,ls[i]): return i
    return -1
def nonblank(ls,i):
    while i<len(ls) and not ls[i].strip(): i+=1
    return i
def path_of(lang,nn): return glob.glob(f'{BOOK}{lang}/{nn}-*.md')[0]
def lines_of(lang,nn): return open(path_of(lang,nn)).read().rstrip('\n').split('\n')

def labels(lang):
    t=lines_of(lang,'04'); o=lines_of(lang,'02')
    tl=next(l for l in t if l.startswith('**') and '`type`' in l).replace('`btree`','`{lib}`')
    ol=next(l for l in o if l.startswith('**') and '`op ::`' in l).replace('`math`','`{lib}`')
    return tl,ol

def section_spec(lib,src,spec):
    bn=banners(src)
    if spec[0]=='sec':
        m=[b for b in bn if b[0].startswith(spec[1])]
        if not m: raise SystemExit(f'{lib}: no section starting with {spec[1]!r}')
        return m[0][0],clean(m[0][1])
    return spec[1],clean(fn_range(src,spec[2],spec[3]))

# ---------- catalog ----------
def regen_catalog(ls,lib,lang,nn):
    h=find(ls,rf'^### {nn}\.2\.2\.')
    if h<0:
        hd=template(lang)['12.2.2'][2]
        ls=[hd if l.startswith('| # |') else l for l in ls]
        if lib=='locale':
            a=find(ls,r'^\| `1` \| `fn :: '); b=a
            while b<len(ls) and re.match(r'^\| `\d+` \|',ls[b]): b+=1
            fns=catalog(src_of(lib))[2]
            ls=ls[:a]+[f'| `{i+1}` | `{l}` | `{r}` |' for i,(l,r) in enumerate(fns)]+ls[b:]
        return ls
    e=find(ls,rf'^## {nn}\.3\.',h)
    while ls[e].strip()!='---': e-=1
    hdr=find(ls,r'^\| #',h,e)
    if hdr<0: return ls
    types,ops,fns=catalog(src_of(lib))
    c=nonblank(ls,h+1); line=ls[c]
    ms=list(re.finditer(r'`(\d+)`',line))[-3:]
    for m,n in reversed(list(zip(ms,(len(types),len(ops),len(fns))))):
        line=line[:m.start(1)]+str(n)+line[m.end(1):]
    tl,ol=labels(lang)
    out=ls[:h+1]+['',line,'']
    if types: out+=[tl.format(lib=lib),'','```ridgun']+types+['```','']
    if ops:   out+=[ol.format(lib=lib),'','```ridgun']+ops+['```','']
    out+=[ls[hdr],ls[hdr+1]]+[f'| `{i+1}` | `{l}` | `{r}` |' for i,(l,r) in enumerate(fns)]+['']
    return out+ls[e:]

# ---------- examples ----------
def tests_of(lib):
    tp=test_path(lib)
    return test_fns(open(tp).read()) if tp else ({},[])
def example_code(lib,tf,order,prefix):
    k=[o for o in order if o.startswith(prefix)]
    if not k: raise SystemExit(f'{lib}: no test function {prefix!r}')
    return clean(tf[k[0]])
def regen_examples(ls,lib,lang,nn):
    s=find(ls,rf'^## {nn}\.3\.')
    if s<0: return ls
    e=find(ls,r'^## ',s+1)
    if e<0: e=len(ls)
    tf,order=tests_of(lib)
    out=ls[:s]; i=s; shown=set(); intro=None; last_head=None
    while i<e:
        l=ls[i]
        m=re.match(rf'^### {nn}\.3\.(\d+)\. ',l)
        if m: last_head=(int(m.group(1)),l)
        if l.startswith('```ridgun'):
            j=i+1
            while not ls[j].startswith('```'): j+=1
            code=ls[i+1:j]; head=code[0].rstrip() if code else ''
            if head in tf and head.startswith('fn :: test'):
                new=clean(tf[head]).split('\n'); shown.add(head)
                if intro is None:
                    k=i-1
                    while not ls[k].strip(): k-=1
                    intro=ls[k]
                out+=['```ridgun']+new+['```']
            else:
                if head.startswith('fn :: test'): REPORT.append(f'{lang}/{nn} {lib}: example shows a test that is gone: {head}')
                out+=ls[i:j+1]
            i=j+1; continue
        out.append(l); i+=1
    add=[(k,p) for k,p in NEW_EXAMPLES.get(lib,[]) if not any(h.startswith(p) for h in shown)]
    if add and lib not in DOMAIN:
        # insert before the '---' that closes the section
        cut=len(out)
        while out[cut-1].strip()!='---': cut-=1
        cut-=1
        tail=out[cut:]; out=out[:cut]
        while out and not out[-1].strip(): out.pop()
        n,hl=last_head
        for key,p in add:
            n+=1
            out+=['',example_heading(hl,nn,n,st(lang,f'ex.{lib}.{key}')),'',intro,'','```ridgun']+example_code(lib,tf,order,p).split('\n')+['```']
        out+=['']+tail
    return out+ls[e:]
def example_heading(model,nn,n,title):
    m=re.match(rf'^### {nn}\.3\.(\d+)\. (.*?): ',model)
    old=m.group(1); label=re.sub(rf'\b{old}\b',str(n),m.group(2),count=1)
    return f'### {nn}.3.{n}. {label}: {title}'

# ---------- internals ----------
def regen_internals(ls,lib,lang,nn):
    s=find(ls,rf'^## {nn}\.4\.')
    if s<0: return ls
    e=find(ls,r'^## ',s+1)
    while ls[e].strip()!='---': e-=1
    first=find(ls,rf'^### {nn}\.4\.1\. ',s,e)
    label=re.match(rf'^### {nn}\.4\.1\. (.*?): ',ls[first]).group(1)
    intro=ls[nonblank(ls,first+1)]
    old=[]; i=first
    while i<e:
        m=re.match(rf'^### {nn}\.4\.\d+\. .*?: (.*)$',ls[i])
        if m:
            a=find(ls,r'^```ridgun',i,e); b=find(ls,r'^```\s*$',a+1,e)
            old.append((m.group(1),ls[a+1:b])); i=b
        i+=1
    src=src_of(lib); bt=[b[0] for b in banners(src)]
    specs=INTERNALS.get(lib)
    blocks=[]
    if specs:
        for sp in specs: blocks.append(section_spec(lib,src,sp))
    else:
        for title,code in old:
            if title in bt: blocks.append(section_spec(lib,src,('sec',title)))
            else:
                c=difflib.get_close_matches(title,bt,n=1,cutoff=0.6)
                if c: blocks.append(section_spec(lib,src,('sec',c[0])))
                else: blocks.append((title,'\n'.join(code)))          # no banner in the source: keep
    if old and old[0][1] and old[0][1][0].startswith('module :: ') and not blocks[0][1].startswith('module :: '):
        blocks[0]=(blocks[0][0],f'module :: {lib}\n\n'+blocks[0][1])
    out=ls[:first]
    for k,(title,code) in enumerate(blocks):
        out+=[f'### {nn}.4.{k+1}. {label}: {title}','',intro,'','```ridgun']+code.split('\n')+['```','']
    return out+ls[e:]

# ---------- prose ----------
def fix_prose(ls,lib,lang,nn):
    for pat,rep in COMMON.get(lang,[]):
        ls=[re.sub(pat,rep,l) for l in ls]
    ls=[l if re.match(r'^\s|^fn |^import ',l) else re.sub(OLD_COUNT+r'( libs?\b| lib-)',rf'{LIB_COUNT}\1',l) for l in ls]
    if lib=='argon2id':
        ls=[l.replace('`Tensor[U64 * 8 * 16]`','`Tensor[U64 * 128]`') for l in ls]
        ls=[re.sub(r'6',r'5',l,count=1) if 'tag_len' in l and l.startswith('| `argon2id hash') else l for l in ls]
        ls=[l.replace('`pwd, salt, m_kib, t, p, tag_len`','`pwd, salt, m_kib, t, p`') for l in ls]
    ls=rename_spans(ls,lib,lang,nn)
    ls=family_tables(ls,lib,lang,nn)
    if f'fix.{lib}.guarantee' in EN:
        h=find(ls,rf'^## {nn}\.5\.'); g=find(ls,r'^- \*\*',h)
        ls[g]=ls[g][:ls[g].index('**: ')+4]+st(lang,f'fix.{lib}.guarantee')
    sub=S[lang].get(f'fix.{lib}.subtitle') or EN.get(f'fix.{lib}.subtitle')
    if sub: ls[0]=ls[0].split(' — ')[0]+' — '+st(lang,f'fix.{lib}.subtitle')
    if f'fix.{lib}.honest' in EN:
        assert ls[2].startswith('## ') and ls[14].startswith('1. '), (lang,nn)
        ls[8]=st(lang,f'fix.{lib}.honest')
    if f'fix.{lib}.desc' in EN:
        assert ls[2].startswith('## ') and ls[14].startswith('1. '), (lang,nn)
        ls[10]=st(lang,f'fix.{lib}.desc')
    if lib in FAMILIES_ADD and lib not in FAMILIES_REPLACE:
        h=find(ls,rf'^### {nn}\.2\.1\.'); a=find(ls,r'^\|---',h); b=a+1
        while ls[b].startswith('|'): b+=1
        have='\n'.join(ls[a:b])
        rows=[f'| {code} | {st(lang,f"fam.{lib}.{key}")} |' for key,code in FAMILIES_ADD[lib] if code not in have]
        ls=ls[:b]+rows+ls[b:]
    return ls

def rename_spans(ls,lib,lang,nn):
    mp=RENAME.get(lib)
    if not mp: return ls
    out=[]; code=False
    for l in ls:
        if l.startswith('```'): code=not code; out.append(l); continue
        if code or re.match(r'^\| `\d+` \|',l) or '`' not in l: out.append(l); continue
        drop_row=False
        def one(m):
            nonlocal drop_row
            span=m.group(1)
            if span in mp:
                return '\0' if mp[span] is None else '`'+mp[span]+'`'
            sep=' / ' if ' / ' in span else ', ' if ', ' in span else None
            items=span.split(sep) if sep else [span]
            if not any(i.strip() in mp for i in items): return m.group(0)
            new=[mp.get(i.strip(),i) for i in items]
            new=[i for i in new if i is not None]
            if not new: return '\0'
            return '`'+(sep or '').join(new)+'`'
        n=re.sub(r'`([^`]+)`',one,l)
        if '\0' in n:
            if n.startswith('| \0'): continue            # a table row about a function that does not exist
            n=re.sub(r',\s*\0','',n); n=re.sub(r'\0,\s*','',n); n=re.sub(r'\s*/\s*\0','',n); n=re.sub(r'\0\s*/\s*','',n)
            n=re.sub(r'\s*\(\0\)','',n)
            if '\0' in n: REPORT.append(f'{lang}/{nn} {lib}: could not remove a name cleanly: {l[:150]}'); n=n.replace('\0','')
        out.append(n)
    return out
def family_tables(ls,lib,lang,nn):
    h=find(ls,rf'^### {nn}\.2\.1\.')
    if h<0: return ls
    a=find(ls,r'^\|---',h); b=a+1
    while b<len(ls) and ls[b].startswith('|'): b+=1
    if lib in FAMILIES_REPLACE:
        return ls[:a+1]+[f'| {code} | {st(lang,f"fam.{lib}.{key}")} |' for key,code in FAMILIES_REPLACE[lib]]+ls[b:]
    for old,(new,key) in FAMILY_ROW.get(lib,{}).items():
        for i in range(a+1,b):
            if ls[i].startswith(f'| {old} |'):
                purpose=st(lang,key) if key.startswith('fam.') else key
                ls[i]=f'| {new} | {purpose} |'
    return ls
def pointer_tpl(lang):
    t=lines_of(lang,'12'); n=lines_of(lang,'13')[0]
    title=n.split(': ',1)[1] if ': ' in n else n
    line=t[-1]
    assert title in line,(lang,title,line)
    return line.replace(title,'{title}').replace('13','{n}').replace('`diff`','`{lib}`')
def h1_title(h1):
    return re.split(r'^# [^:]*: ',h1,maxsplit=1)[1] if re.match(r'^# [^:]*: ',h1) else h1[2:]

# ---------- new chapters ----------
def template(lang):
    """The lines of chapter 12 that are the same in every chapter, found by their place in each section."""
    t=lines_of(lang,'12'); sec={}; cur=None; code=False
    for l in t:
        if l.startswith('```'): code=not code; continue
        if code or not l.strip() or l.strip()=='---': continue
        if l.startswith('# '): cur='h1'; sec[cur]=[]
        elif l.startswith('#'): cur=re.sub(r'^#+ ([\d.]*).*',r'\1',l).rstrip('.') or 'rules'; sec[cur]=[]
        sec[cur].append(l)
    return sec
def build_chapter(lang,nn,lib):
    t=template(lang); dom=DOMAIN[lib]
    R=lambda s: s.replace('GLOB',dom).replace('glob',lib)
    H=lambda s: re.sub(r'^(#+ )12\.',rf'\g<1>{nn}.',R(s))
    tf,order=tests_of(lib); src=src_of(lib)
    s1=t['12.1']; s2=t['12.2']; s5=t['12.5']; rules=t['rules']
    o=[R(t['h1'][0].split(' — ')[0]).replace('12',nn)+' — '+st(lang,f'ch.{lib}.subtitle'),'',H(s1[0]),'',R(s1[1]),'',R(s1[2]),'',
       st(lang,f'ch.{lib}.honest'),'',st(lang,f'ch.{lib}.desc'),'',R(s1[5]),'']+[R(x) for x in s1[6:10]]+['','---','']
    o+=[H(s2[0]),'',R(s2[1]),'']+[R(x) for x in s2[2:5]]+['',R(s2[5]),'',H(t['12.2.1'][0]),'',t['12.2.1'][1],t['12.2.1'][2]]
    o+=[f'| {code} | {st(lang,f"fam.{lib}.{key}")} |' for key,code in FAMILIES[lib]]
    o+=['',H(t['12.2.2'][0]),'',R(t['12.2.2'][1]),'',t['12.2.2'][2],t['12.2.2'][3],'','---','']
    o+=[H(t['12.3'][0]),'',R(t['12.3'][1]),'']
    for k in (0,1):
        e=t[f'12.3.{k+1}']
        o+=[H(e[0]),'',R(e[1]),'','```ridgun']+HAND[lib][k].rstrip('\n').split('\n')+['```','']
    model=H(t['12.3.3'][0])
    for k,(key,p) in enumerate(NEW_EXAMPLES[lib]):
        o+=[example_heading(model,nn,k+3,st(lang,f'ex.{lib}.{key}')),'',R(t['12.3.3'][1]),'','```ridgun']+example_code(lib,tf,order,p).split('\n')+['```','']
    o+=['---','',H(t['12.4'][0]),'',R(t['12.4'][1]),'']
    label=re.match(r'^### 12\.4\.1\. (.*?): ',t['12.4.1'][0]).group(1)
    for k,sp in enumerate(INTERNALS[lib]):
        title,code=section_spec(lib,src,sp)
        o+=[f'### {nn}.4.{k+1}. {label}: {title}','',R(t['12.4.1'][1]),'','```ridgun']+code.split('\n')+['```','']
    g=s5[1]; gp=g[:g.index('**: ')+4]
    o+=['---','',H(s5[0]),'',gp+st(lang,f'ch.{lib}.guarantee')]+[R(x) for x in s5[2:5]]+['',R(rules[0]),'']+[R(x) for x in rules[1:6]]
    o=regen_catalog(o+['','---','','## end'],lib,lang,nn)[:-4]
    return o

def set_ending(ls,lang,nxt):
    """every chapter ends with '---', blank, pointer to the next chapter (or the closing line for the last one)"""
    tpl=pointer_tpl(lang)
    while ls and not ls[-1].strip(): ls.pop()
    # drop an existing pointer/closing paragraph (a last paragraph after a final '---')
    k=len(ls)-1
    while k>0 and ls[k].strip()!='---' and not ls[k].startswith(('```','#','- ','|')) and not re.match(r'^\d+\. ',ls[k]): k-=1
    if ls[k].strip()=='---': ls=ls[:k]
    while ls and not ls[-1].strip(): ls.pop()
    last=ls+['','---','']
    if nxt is None: return last+[st(lang,'book.closing')]
    n,lib,title=nxt
    return last+[tpl.format(n=n,lib=lib,title=title)]

def update_index(lang):
    p=f'{BOOK}{lang}/INDEX.md'; ls=open(p).read().rstrip('\n').split('\n')
    ls=[l if re.match(r'^\| `\d\d-lib-',l) else re.sub(OLD_COUNT+r'( libs?\b| lib-| lib\b|-lib guide)',rf'{LIB_COUNT}\1',l) for l in ls]
    cells=next(l for l in ls if l.startswith('| `12-lib-glob')).split(' | ')
    out=[]; have=set()
    for l in ls:
        m=re.match(r'^\| `(\d\d)-lib-[^`]*` \| ',l)
        if m:
            nn=m.group(1); parts=l.split(' | '); have.add(nn)
            parts[0]=f'| `{os.path.basename(path_of(lang,nn))}`'
            parts[1]=open(path_of(lang,nn)).readline().strip()[2:]
            l=' | '.join(parts)
        out.append(l)
    last=max(i for i,l in enumerate(out) if re.match(r'^\| `\d\d-lib-',l))
    new=[]
    for f in chapters(lang):
        nn=os.path.basename(f)[:2]
        if nn in have: continue
        lib=lib_of(f); dom=DOMAIN.get(lib,lib.upper())
        new.append(f'| `{os.path.basename(f)}` | {open(f).readline().strip()[2:]} | '+cells[2].replace('GLOB',dom).replace('glob',lib))
    open(p,'w').write('\n'.join(out[:last+1]+new+out[last+1:])+'\n')
def update_counts():
    n=len(chapters('en'))
    for p in (BOOK+'INDEX.md',BOOK+'build_book.py'):
        t=open(p).read()
        if _prev!=str(n):
            t='\n'.join(re.sub(rf'\b{_prev}\b',str(n),l) if re.search(r'page_title|brand_subtitle|footer_text|^\| `[a-z][a-z]/` ',l.strip()) else l for l in t.split('\n'))
        open(p,'w').write(t)
def main():
    for lang in LANGS:
        files={}
        for f in chapters(lang):
            nn=os.path.basename(f)[:2]; lib=lib_of(f)
            ls=open(f).read().rstrip('\n').split('\n')
            ls=fix_prose(ls,lib,lang,nn)
            ls=regen_catalog(ls,lib,lang,nn)
            ls=regen_examples(ls,lib,lang,nn)
            ls=regen_internals(ls,lib,lang,nn)
            if f'slug.{lib}' in EN:                      # a chapter whose file name changed
                new=f'{BOOK}{lang}/{nn}-lib-{lib.replace("_","-")}-{st(lang,f"slug.{lib}")}.md'
                if new!=f: os.remove(f); f=new
            files[nn]=[f,lib,ls]
        for nn,lib in NEW_CHAPTERS:
            ls=fix_prose(build_chapter(lang,nn,lib),lib,lang,nn)
            files[nn]=[f'{BOOK}{lang}/{nn}-lib-{lib}-{st(lang,f"ch.{lib}.slug")}.md',lib,ls]
        nums=sorted(files)
        for i,nn in enumerate(nums):
            f,lib,ls=files[nn]
            nxt=None
            if i+1<len(nums):
                nf,nlib,nls=files[nums[i+1]]; nxt=(nums[i+1],nlib,h1_title(nls[0]))
            ls=set_ending(ls,lang,nxt)
            open(f,'w').write('\n'.join(ls).rstrip('\n')+'\n')
        update_index(lang)
    update_counts()
    for r in sorted(set(REPORT)): print('REPORT',r)
    print('missing strings:',len(MISSING),sorted({l for l,_ in MISSING}))
main()
