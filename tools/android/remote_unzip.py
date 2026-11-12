"""Wypakowuje wybrane pliki z archiwum ZIP w internecie bez pobierania całości (zapytania o fragmenty pliku).
Użycie: python3 remote_unzip.py <adres> <fragment nazwy> [...] - pliki trafiają do bieżącego folderu."""
import io, sys, zipfile, urllib.request
URL = sys.argv[1]
class RangeFile(io.RawIOBase):
    def __init__(self, url):
        self.url = url; self.pos = 0
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req) as r:
            self.url = r.geturl(); self.size = int(r.headers["Content-Length"])
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.pos
    def seek(self, off, whence=0):
        self.pos = off if whence == 0 else self.pos + off if whence == 1 else self.size + off
        return self.pos
    def readinto(self, b):
        n = min(len(b), self.size - self.pos)
        if n <= 0: return 0
        req = urllib.request.Request(self.url, headers={"Range": f"bytes={self.pos}-{self.pos+n-1}"})
        data = urllib.request.urlopen(req).read()
        b[:len(data)] = data; self.pos += len(data); return len(data)
f = io.BufferedReader(RangeFile(URL), buffer_size=1 << 20)
z = zipfile.ZipFile(f)
print(f.raw.size)
for i in z.infolist():
    if any(k in i.filename for k in sys.argv[2:]):
        print(i.filename, i.file_size)
        name = i.filename.split("/")[-1]
        with z.open(i) as src, open(name, "wb") as dst:
            while chunk := src.read(1 << 20): dst.write(chunk)
