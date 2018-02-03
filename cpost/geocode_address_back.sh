#!/bin/bash
# 

#
# v JOSM: 
#		používá plugin Opendata pro zobrazení CSV jako vrstvy
#		používá plugin Utilsplugin2 pro vytváření odkazů do map
#		customurl.txt s definicemi map



sBS="cpost_NoCoord2.txt"	# soubor bez souřadnic
sGC="out30071.csv"	# soubor se souřadnicemi + detaily
dtS=`date +%Y%m -r "$sGC"`
dtN=`date +%Y%m%d`
# další zpracování po geokódování

# sloučit, přeformátovat pro další zpracování, doplnit datum, rozdělit podle přesnosti 
    paste "$sBS" "$sGC" | 
        awk -F$'\t' '{ print $1"\t"$9"\t"$10"\t"$2": "$3"\t"$6": "$14"\t"$5"\tpost_box\tČeská pošta s.p.\tcp:" }' |
        sed "s/establishment,*//; s/point_of_interest,*//; s/food,*//; s/health,*//; s/, Czechia//; s/,\t/\t/g; s/$/$dtS/" | 
        sort | 
        join -t$'\t' -j 1 - cpost_id_collection_time.txt |
        awk -F$'\t' '{print > "sBSGC_"$6".txt" }'

# přesnost "ROOFTOP" a "GEOMETRIC CENTER" do dat společně?
    echo ref$'\t'latitude$'\t'longitude$'\t'note$'\t'geocoding:address$'\t'geocoding:quality$'\t'amenity$'\t'operator$'\t'source$'\t'collection_time | 	# hlavičky
        cat - sBSGC_ROOFTOP.txt sBSGC_GEOMETRIC_CENTER | 
        awk -F$'\t' '{print "!"$1"!;"$2";"$3";!"$4"!;!"$5"!;!"$6"!;!"$7"!;!"$8"!;!"$9"!;!"$10"!;!"$11"!" }' | tr '!' '\"' > JOSM_import_$dtS.csv	# potřebuje plugin opendata

# nepřesné, pro jistotu:
    echo ref$'\t'latitude$'\t'longitude$'\t'note$'\t'geocoding:address$'\t'geocoding:quality$'\t'amenity$'\t'operator$'\t'source$'\t'collection_time | 	# hlavičky
        cat - sBSGC_APPROXIMATE.txt sBSGC_RANGE_INTERPOLATED.txt | 
        awk -F$'\t' '{print "!"$1"!;"$2";"$3";!"$4"!;!"$5"!;!"$6"!;!"$7"!;!"$8"!;!"$9"!;!"$10"!;!"$11"!" }' | tr '!' '\"' > JOSM_no_import_$dtS.csv

# neúspěšné: znovu
	  cut -f1,4 sBSGC_.txt |
		tee DalsiPokus.txt |	# originály
		cut -f1,4 sBSGC_.txt | grep "(" | 
		awk -F"[\t():]" '{ print $1":"$2"\t\""$3" "$5"\"\t"$4 }' | sed 's/ \+,/,/; s/,\+/,/' > nove.txt
exit

# pokračuje spojení +přidání do tabulky souřadnic
sed "s/\r//; s/ \+/\t/g; s/^\t//g" convert_rooftop2.txt | 	# změna formátu souboru z EasyTransform
join -t$'\t' -o 1.1,1.2,1.3,2.2,2.3 - convert_rooftop.txt | 	# spojit
sed "s/$/\tR\t$dtN/" >> cp_ref_coord_geocoded.txt	# doplnit "přesnost" a "datum přidání"

# záloha souborů
cp rooftop.txt rooftop_$dtN.txt