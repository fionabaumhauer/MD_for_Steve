"""
This script takes the coordinates from the temp.xyz file created by packmol and puts them in a lammps.data file
"""

# atom types & charges
atom_info = {
    "C": (1, 0.70),
    "O": (2, -0.35),
    "X": (3, 0.964),
    "N": (4, -0.482),
}

xyz_file = "temp.xyz"

# Read XYZ and generate Atoms section
atoms = []
X_count = 0
C_count = 0
with open(xyz_file) as f:
    lines = f.readlines()
    # num_atoms = int(lines[0].strip())
    coord_lines = lines[2:]  # skip first 2 lines

    atom_id = 1
    molecule_id = 1
    for i,line in enumerate(coord_lines):
        parts = line.split()
        element = parts[0]
        x, y, z = map(float, parts[1:4])

        if element not in atom_info:
            raise ValueError(f"Element {element} notin atom_info")

        if element == "X":
            X_count += 1
        if element == "C":
            C_count += 1

        atom_type, charge = atom_info[element]
        atoms.append((atom_id, molecule_id, atom_type, charge, x, y, z, 0, 0, 0))
        atom_id += 1
        # every three lines increase molecule id
        if (i + 1) % 3 == 0:
            molecule_id += 1

atoms_str = "Atoms # full\n\n" + "\n".join(" ".join(map(str, a)) for a in atoms)

# generate Bonds section
bonds = []
bond_id = 1

for mol_start in range(0, len(atoms), 3):
    # atoms in this molecule
    a1, a2, a3 = atoms[mol_start:mol_start+3]
    # create bonds: a1-a2, a1-a3
    bonds.append((bond_id, 1, a1[0], a2[0]))
    bond_id += 1
    bonds.append((bond_id, 1, a1[0], a3[0]))
    bond_id += 1

bonds_str = "Bonds\n\n" + "\n".join(" ".join(map(str, b)) for b in bonds)

# make data file

total_atoms = len(atoms)
total_bonds = len(bonds)

data_contents = f"""\
LAMMPS data file for n2/co2

{total_atoms} atoms
4 atom types
{total_bonds} bonds
2 bond types

0 36  xlo xhi
0 36  ylo yhi
0 36  zlo zhi

Masses

1 12.0107
2 15.9999
3 28.0134
4 2

Pair Coeffs # lj/cut/coul/long

1 0.0536548 2.8
2 0.15699 3.05
3 0 0
4 0.0715394 3.31

{atoms_str}

{bonds_str}
"""

with open("initialMD.data", "w") as f:
    f.write(data_contents)
