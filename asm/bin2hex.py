import sys

with open(sys.argv[1], "rb") as f:
    d = f.read()

with open(sys.argv[2], "w") as f:
    for i in range(0, len(d), 4):
        w = d[i:i+4]
        w += b"\x00" * (4 - len(w))
        # Little endian -> Big endian hex strings for Verilog readmemh
        f.write(f"{w[3]:02x}{w[2]:02x}{w[1]:02x}{w[0]:02x}\n")
