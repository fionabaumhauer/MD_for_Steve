#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_LAMMPS="$SCRIPT_DIR/in.lammps"
PYTHON_SCRIPT="$SCRIPT_DIR/convert_xyz_to_data.py"
TEMPLATE_XYZ="/scratch/fb590/co2n2/electric/prepareMD/templates/CO2.xyz"
BOX_VOL=46656  # 36^3 Angstrom^3

low_T_densities=(0.001072 0.002143 0.004287 0.013932 0.015003)
high_T_densities=(0.001072 0.002143 0.004287 0.006430 0.008573 0.010717 0.012860 0.013932 0.015003)

for temp in 250 275 375 500; do
    T_dir="$SCRIPT_DIR/T${temp}"
    mkdir -p "$T_dir"

    if [ "$temp" -le 275 ]; then
        densities=("${low_T_densities[@]}")
    else
        densities=("${high_T_densities[@]}")
    fi

    # Write densities.csv for this temperature
    csv_file="$T_dir/densities.csv"
    > "$csv_file"
    for density in "${densities[@]}"; do
        nmol=$(awk "BEGIN {printf \"%.0f\", $density * $BOX_VOL}")
        echo "$density,$nmol" >> "$csv_file"
    done

    # Create rho directories
    i=1
    while IFS=',' read -r density nmol; do
        dir="$T_dir/rho_$i"
        mkdir -p "$dir"

        cat > "$dir/packmol.inp" <<EOF
tolerance 2
output temp.xyz
filetype xyz
seed 28446

structure $TEMPLATE_XYZ
   number  $nmol
   inside box 2.0 2.0 2.0 32.0 32.0 32.0
end structure
EOF

        sed -E "s/variable +temperature +equal +[0-9]+/variable      temperature equal $temp/" \
            "$TEMPLATE_LAMMPS" > "$dir/in.lammps"

        echo "Setting up $dir  (density=$density, nmol=$nmol, T=${temp}K)"
        (cd "$dir" && packmol < packmol.inp && python "$PYTHON_SCRIPT")

        ((i++))
    done < "$csv_file"
done
