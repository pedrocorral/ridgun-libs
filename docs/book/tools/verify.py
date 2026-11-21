"""Check the book against the sources. Exit code 1 when something does not match.

- every function name quoted in titles, tables and paragraphs exists (in a lib, the prelude, or the list below);
- every hand-written example (a block that starts with `import`) passes `ridgunc check`;
- every "under the hood" line is in the lib source, and every test example line is in the test."""
from common import *
import subprocess,hashlib,sys,tempfile,shutil
defs=set()
def addnames(text):
    for l in text.split('\n'):
        m=re.match(r'^\s*(?:fn|op|cpu op) :: (.*?)\s*=>',l)
        if m:
            n=[]
            for x in m.group(1).split():
                if re.match(r'^[A-Z(\[]',x): break
                n.append(x)
            defs.add(' '.join(n))
for f in glob.glob(SRC+'*.ridgun'): addnames(open(f).read())
addnames(subprocess.run('ulimit -v 4000000; ridgunc prelude',shell=True,capture_output=True,text=True).stdout)
BUILTIN={'str len','str slice','str contains','str starts with','str join','str char at','int to str','str to int','char from code','read file','write file','sys pipe','sys poll','sys close','sys read fd','sys write fd',
 'sys os','sys arch','sys time ms','sys wall time ms','send ... to','receive from','try receive from','sys open mode','shell exec','cli args','sys mkdir','sys exit','with region','with timeout','sys deadline ms','sys remaining ms',
 'siphash13 range','siphash13 range low','clamp x between lo and hi','export argon2id','cpu op','new channel','send through','sys lstat','sys getenv','sys exec','sys fork','sys read','sys write'}
def names_report(lang='en'):
    tot=0
    for f in chapters(lang):
        nn=os.path.basename(f)[:2]; c=False; bad={}
        for i,l in enumerate(open(f).read().split('\n')):
            if l.startswith('```'): c=not c; continue
            if c or re.match(r'^\| `\d+` \|',l): continue
            for span in re.findall(r'`([^`]+)`',l):
                for part in re.split(r' / |, ',span):
                    part=part.strip()
                    if re.match(r'^[a-z][a-z0-9]*( [a-z0-9]+)+$',part) and not part.startswith(('import ','module ','fn ','stable ','my fn','x my','input step','step two','s with','ridgunc ','git ','op ')):
                        if part not in defs and part not in BUILTIN: bad.setdefault(part,[]).append(i+1)
        if bad: tot+=len(bad); print(nn,{k:v[:2] for k,v in bad.items()})
    print('unknown names:',tot)
    return tot
def code_report():
    libdir=tempfile.mkdtemp(prefix='book-check-')
    for f in glob.glob(SRC+'*.ridgun'): open(libdir+'/'+os.path.basename(f),'w').write(open(f).read())
    seen={}; bad=0; nb=0
    for lang in LANGS:
        for f in chapters(lang):
            lib=lib_of(f); nn=os.path.basename(f)[:2]
            src=re.sub(r'\s+',' ',src_of(lib)); tp=test_path(lib); tst=re.sub(r'\s+',' ',open(tp).read()) if tp else ''
            t=open(f).read()
            s4=t.find(f'\n## {nn}.4.'); s5=t.find(f'\n## {nn}.5.'); s3=t.find(f'\n## {nn}.3.')
            for m in re.finditer(r'```ridgun\n(.*?)```',t,re.S):
                code=m.group(1); pos=m.start(); nb+=1
                if code.startswith('import '):
                    h=hashlib.md5(code.encode()).hexdigest()[:10]
                    if h not in seen:
                        open(f'{libdir}/zzv{h}.ridgun','w').write(code)
                        r=subprocess.run(f'cd {libdir}; ulimit -v 4000000; timeout 120 ridgunc check zzv{h}.ridgun 2>&1',shell=True,capture_output=True,text=True).stdout
                        seen[h]='0 error(s).' in r
                        if not seen[h]: bad+=1; print('HAND FAILS',lang,nn,[l[:120] for l in r.split('\n') if 'error' in l][:2])
                elif s4>0 and s4<pos<s5:
                    miss=[l for l in code.split('\n') if l.strip() and not l.startswith('module ::') and re.sub(r'\s+',' ',l).strip() not in src]
                    if miss: bad+=1; print('INTERNALS not in source',lang,nn,len(miss),miss[0][:80])
                elif s3>0 and s3<pos and code.startswith('fn :: test'):
                    miss=[l for l in code.split('\n') if l.strip() and re.sub(r'\s+',' ',l).strip() not in tst]
                    if miss: bad+=1; print('EXAMPLE not in test',lang,nn,len(miss),miss[0][:80])
    shutil.rmtree(libdir)
    print('blocks',nb,'unique hand examples',len(seen),'problems',bad)
    return bad
if __name__=='__main__':
    sys.exit(1 if names_report()+code_report() else 0)
