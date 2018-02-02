#!/bin/bash
# 

#
sBS="cpost_NoCoord2.txt"	# soubor bez souřadnic
sGC="out30071.csv"	# soubor se souřadnicemi + detaily
dtS=`date +%Y%m -r "$sGC"`
dtN=`date +%Y%m%d`
# další zpracování po geokódování


paste "$sBS" "$sGC" | grep ROOFTOP | 	# největší přesnost
awk -F$'\t' '{ print $1"\t"$9"\t"$10"\t<b>"$2"</b><br>"$3"\t"$6"<br>"$14"\tpost_box\tČeská pošta s.p.\tcp:" }' | 
sed "s/establishment,*//; s/point_of_interest,*//; s/food,*//; s/health,*//; s/, Czechia//; s/$/$dtS/" | 
tee rooftop.txt | 
cut -f-3 | sed "s/$/\t0/" > convert_rooftop.txt	# Křovák


exit
# pokračuje spojení +přidání do tabulky souřadnic
sed "s/\r//; s/ \+/\t/g; s/^\t//g" convert_rooftop2.txt | 	# změna formátu souboru z EasyTransform
join -t$'\t' -o 1.1,1.2,1.3,2.2,2.3 - convert_rooftop.txt | 	# spojit
sed "s/$/\tR\t$dtN/" >> cp_ref_coord_geocoded.txt	# doplnit "přesnost" a "datum přidání"

# záloha souborů
cp rooftop.txt rooftop_$dtN.txt