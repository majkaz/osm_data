#!/bin/bash
# 

#
sBS="cpost_NoCoord2.txt"	# soubor bez souřadnic
sGC="out30071.csv"	# soubor se souřadnicemi + detaily
dtS=`date +%Y%m -r "$sGC"`
dtN=`date +%Y%m%d`
# další zpracování po geokódování

# sloučit, přeformátovat pro další zpracování, doplnit datum, rozdělit podle přesnosti 
paste "$sBS" "$sGC" | 
awk -F$'\t' '{ print $1"\t"$9"\t"$10"\t"$2"<br>"$3"\t"$6"<br>"$14"\t"$5"\thttps://www.google.com/maps/@?api=1&map_action=pano&viewpoint="$9","$10"&heading=-45&pitch=0&fov=80\tpost_box\tČeská pošta s.p.\tcp:" }' |
sed "s/establishment,*//; s/point_of_interest,*//; s/food,*//; s/health,*//; s/, Czechia//; s/,\t/\t/g; s/$/$dtS/" | 
sort | 
join -t$'\t' -j 1 - cpost_id_collection_time.txt |
awk -F$'\t' '{print > "sBSGC_"$6".txt" }'


exit

# pokračuje spojení +přidání do tabulky souřadnic
sed "s/\r//; s/ \+/\t/g; s/^\t//g" convert_rooftop2.txt | 	# změna formátu souboru z EasyTransform
join -t$'\t' -o 1.1,1.2,1.3,2.2,2.3 - convert_rooftop.txt | 	# spojit
sed "s/$/\tR\t$dtN/" >> cp_ref_coord_geocoded.txt	# doplnit "přesnost" a "datum přidání"

# záloha souborů
cp rooftop.txt rooftop_$dtN.txt