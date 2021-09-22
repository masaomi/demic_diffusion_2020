
for i in {0..9}; do
    seed=$RANDOM
    echo $seed
    ruby scripts/genetics_diffusion_v6_only_human_no_spatial_structure.rb -hm 0.0 -n 500 -s $seed -o out_$seed
done

