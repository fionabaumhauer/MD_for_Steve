#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$SCRIPT_DIR/densities.csv"
TEMPLATE_PATH="/scratch/fb590/co2n2/electric/prepareMD/templates/CO2.xyz"
PYTHON_SCRIPT="/scratch/fb590/co2n2/electric/MD_for_Steve/pressure_vs_density/convert_xyz_to_data.py"

i=1
while IFS=',' read -r density nmol_raw; do
    nmol=$(printf "%.0f" "$nmol_raw")
    dir="$SCRIPT_DIR/rho_$i"
    mkdir -p "$dir"
    cat > "$dir/packmol.inp" <<EOF
tolerance 2
output temp.xyz
filetype xyz
seed 28446

structure $TEMPLATE_PATH
   number  $nmol
   inside box 2.0 2.0 2.0 32.0 32.0 32.0
end structure
EOF
    echo "Created $dir/packmol.inp  (density=$density, nmol=$nmol)"

    cp "$SCRIPT_DIR/in.lammps" "$dir/in.lammps"
    (cd "$dir" && packmol < packmol.inp && python "$PYTHON_SCRIPT")

    ((i++))
done < "$CSV"


