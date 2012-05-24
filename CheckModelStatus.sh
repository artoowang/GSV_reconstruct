#!/bin/bash
# Check on the status of each model

for id in $(ls data)
do
    dir="data/$id"
	if [ -e $dir/.processing ]
	then
		printf "%04d status: 2\n" $id
    elif [ -e $dir/bundles_new ]
    then
        good_components=`ls $dir/bundles_new/ | grep ".out$" | wc -l | awk '{print $1}'`

        # Has the model been cleaned?
        num_images=`ls $dir/images/ | grep ".key" | wc -l | awk '{print $1}'`
        list_size=`wc -l $dir/list.txt | awk '{print $1}'`

        if [ $num_images -eq $list_size ]
        then
            clean=0
        else
            clean=1
        fi

		# Check each bundle file
        printf "%s status: 1  good_components: %d  clean: %d\n" $id $good_components $clean
		for comp in `ls $dir/bundles_new/ | sed -n 's/bundle\.\(.*\)\.out/\1/p'`
		do
			# Find the original component size (can be zero-string if bundler-script.txt does not have that component)
			comp_size=`grep "component $comp\s" "$dir/bundler-script.txt" | sed -n 's/#.*(size\s*=\s*\([0-9]*\)).*/\1/p'`

			# The list file tells us how many images we have in each reconstructed component
			list_file=$dir/bundles_new/list.${comp}.txt
			if [ -e "$list_file" ]; then
				recon_size=`wc -l $list_file | awk '{print $1}'`
				if [ -n "$comp_size" ]; then
					echo "  component $comp: $recon_size out of $comp_size reconstructed"
				else
					echo "Error: component $comp is not found in bundler-script.txt; no original component size" 1>&2
					echo "  component $comp: $recon_size out of -1 reconstructed"
				fi
			else
				echo "Error: list file $list_file does not exist" 1>&2
				echo "  component $comp: -1 out of -1 reconstructed"
			fi
		done

    else
        printf "%s status: 0\n" $id
    fi
done
