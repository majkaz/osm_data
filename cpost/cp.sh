#!/bin/bash
# 

# potřebuje datamash ve zdrojovém adresáři: check

# jméno souboru z pošty (.csv) jako parametr, získání data souboru
cp_file=`basename "$1"`
cp_date=${cp_file%.*}  
cp_date=${cp_date##*_}  

# proměnné pro formátování výstupu na terminál
b=$(tput bold)
n=$(tput sgr0)

# nezměnily se hlavičky?
cp_header=`head -n1 $cp_file | tr -d '\r'`
h_txt="psc;zkrnaz_posty;cis_schranky;adresa;sour_x;sour_y;misto_popis;cast_obce;obec;okres;cas;omezeni"
h_tab="ref\tpsc\tzkrnaz_posty\tcis_schranky\tadresa\tsour_x\tsour_y\tmisto_popis\tcast_obce\tobec\tokres\tcas\tomezeni"


if [ $cp_header != $h_txt ]
then 
    echo "Záhlaví souboru je $cp_header"
    echo "Byla očekávána struktura:"
    echo $h_txt
    echo "Skript nemůže s touto strukturou pracovat."
    exit
fi

echo
echo "Soubor je $cp_file, data z ${b}$cp_date${n}"
echo "Konverze souborů pro další zpracování..."
echo


# konvertovat vstupní soubor do tab separated
echo 
	dos2unix < $cp_file | iconv -f cp1250 -t utf-8 | tr ';'  '\t' | 
		tee temp.tab | # do dočasného
		cut -f 1,3 | tr '\t' ':' | paste - temp.tab | # přidat ref
		tee temp2.tab | 
		awk -F$'\t' 'NF != 13' |  # chybně rozdělené řádky
		tee cpost_err.csv # je možné spravit?
echo
echo "----------------------------------"
echo
# vybrat jen řádky se správným počtem polí
	awk -F$'\t' 'NF == 13' temp2.tab | # správné
		# <-- sem připojit spravené 
		tail -n+2 | sort -t$'\t' -k 13 > temp.tab  # setřídit podle dnů výběru, vynech záhlaví
		echo -e "$h_tab" | cat - temp.tab > temp_no_join.tab  
	join --header -t$'\t' -1 13 -2 1 temp_no_join.tab cp_ref_dny_konverze.txt | tee temp_zpracovani.tab | # připojit konverzní tabulku
# sloučení doby výběru
	datamash --header-in -g omezeni,ref,dny collapse cas first 3-12  > temp_cas.tab 
	paste -d' ' <(cut -f-3 temp_cas.tab) <( cut -f 4- temp_cas.tab ) | tee temp_dny.tab 
# spojení den+cas
	echo -e "omezeni\tref\tvyber\tpsc\tpsc\tzkrnaz_posty\tcis_schranky\tadresa\tsour_x\tsour_y\tmisto_popis\tcast_obce\tobec\tokres" > temp_dny_slouc.tab
	datamash -g 2 collapse 3 first 4-13 < temp_dny.tab >> temp_dny_slouc.tab # sloučení dní
	exit 
	exit 
	
	exit
	# rm temp.tab temp2.tab
#
exit
# rozdělit na část se souřadnicemi a bez souřadnic
	awk -F"\t" '$5 == ""' temp_zpracovani.tab > "$cp_date"_NoCoord.tab

# konverze souřadnic Křovák - WGS, jen pro schránky se souřadnicemi
# potřebuje cs2cs, datamash
	awk -F"\t" '$5 != ""' temp_zpracovani.tab |
		tee "$cp_date"_Coord.tab | # pro jistotu
		datamash -H -g psc,cis_schranky first sour_x,sour_y | 
		tail -n+2 | tee krovak.tab | # vrácení souřadnic
		cut -f3- | sed 's/^/-/; s/\t/\t-/' > temp.tab # negativní souřadnice
	cs2cs -f "%f" +proj=krovak +ellps=bessel +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56 +to +init=epsg:4326 temp.tab | 
		cut -f2- | tr ' ' '\t' | paste krovak.tab - | 
		cat <(echo "psc;cis_schranky;sour_y;sour_x;latitude;longitude" | tr ';' '\t' ) - |
		tee konvertovane.tab |
		paste "$cp_date"_Coord.tab - | cut -f-14,17- > "$cp_date"_Coord_complete.tab

# collection_time
datamash -Hs -g psc,cis_schranky,omezeni collapse cas first latitude,longitude,misto_popis,cast_obce,obec,okres < "$cp_date"_Coord_complete.tab | 
(read -r; printf "%s\n" "$REPLY"; sort -t$'\t' -k 3 ) | # setřídit, vynech záhlaví
join --header -t$'\t' -1 1 -2 3 cp_ref_dny_konverze.txt - > temp.tab

exit 

# sloučení den + hodina
paste -d' ' <( cut -f2 temp.tab) <( cut -f5 temp.tab ) | paste - <( cut -f 3-4,6- temp.tab) | 
# sloučení dny výběru
paste -d' ' <( cut -f2 temp.tab) <( cut -f5 temp.tab ) | 
paste - <( cut -f 3-4,6- temp.tab) | tail -n+2 | 
tee temp2.tab |
datamash -g 2,3 collapse 1 first 4-9 | 
cat <(echo "psc;cis_schranky;collection_times;latitude;longitude;misto_popis;cast_obce;obec;okres" | tr ';' '\t') - > temp.tab




rm temp.tab krovak.tab # ukliď


echo "Hotovo"

exit


# check history, pokud neexistuje, pro jistotu vytvoř prázdné soubory
if [ ! -f cp_ref_coord_history.txt ]; then touch cp_ref_coord_history.txt ;fi
if [ ! -f cp_ref_coord_source.txt ]; then touch cp_ref_coord_source.txt;fi
if [ ! -f cp_ref_dny_konverze.txt ]; then touch cp_ref_dny_konverze.txt;fi
if [ ! -f cp_ref_id_collection_time_history.txt ]; then touch cp_ref_id_collection_time_history.txt ;fi
# check geokodované, odečítají se později
if [ ! -f sBSGC_ROOFTOP.txt ]; then touch ROOFTOP.txt ;fi
if [ ! -f sBSGC_GEOMETRIC_CENTER.txt ]; then touch sBSGC_GEOMETRIC_CENTER.txt ;fi

# nezměnily se hlavičky?
cp_header=`head -n1 $cp_file | tr -d '\r'`
h_txt="psc;zkrnaz_posty;cis_schranky;adresa;sour_x;sour_y;misto_popis;cast_obce;obec;okres;cas;omezeni"

if [ $cp_header != $h_txt ]
then 
    echo "Záhlaví souboru je $cp_header"
    echo "Byla očekávána struktura:"
    echo $h_txt
    echo "Skript nemůže s touto strukturou pracovat."
    exit
fi

echo
echo "Soubor je $cp_file, data z ${b}$cp_date${n}"
echo "Konverze souborů pro další zpracování..."
echo

# konverze + přidání ID schránky + kontrola počtu polí + odříznutí hlaviček
iconv -f cp1250 -t utf-8 $cp_file | dos2unix |	# konverze utf-8 + \n
    tr ';' '\t' |	# tab separated  "
    awk -F$'\t' ' { print $1":"$3"\t"$0} ' |	# přidat ref
    tail -n+2 |	# odříznout hlavičky
    sort -t$'\t' -k1 |	# setřídit podle ref
    awk -F$'\t' '{if (NF!=13) {print > "cpost_err.csv"} else {print > "cpost_ps.csv"}}'	# kontrola počtu polí (13), vytvoření chybového souboru


echo "Vytvořen pracovní soubor ${b}cpost_ps.csv${n}"
echo "a chybový soubor ${b}cpost_err.csv${n}"
echo


# nové/změněné koordináty ke zkonvertování
./datamash rmdup 1 < cpost_ps.csv |	# deduplikace->ref pro zrychlení
    dos2unix |	# datamash win64 -> out \r\n
    sort |	# použije se později
    tee cpost_crude_dedup.txt |	# vytvoření souboru pro další zpracování
    cut -f1,6-7 |	# jen ref, souřadnice x a y
    awk '{if($2) print }' |	# má souřadnice?
    tee cp_ref_coord_source.txt |	# uložení souboru se souřadnicemi 
    awk -F$'\t' 'NR==FNR{ a[$2]=$0;next } NF{ if(a[$2]==$1$2$3) print $0 }' - cp_ref_coord_history.txt |	# porovnání s dříve zkonvertovaným, pro rozdíly:
    sed 's/\./,/g;s/$/\t0/' |	# přeformátování pro EasyTransform
    iconv -f utf-8 -t cp1250 | unix2dos |	# konverze zpět pro EasyTransform
    tr '\t' ' ' > cp_konvertovat.txt	# vytvoření souboru pro konverzi

# zrušené schránky?
join -t$'\t' -v 2 cpost_crude_dedup.txt cp_ref_ids.txt > ids_zruseno_$cp_date.txt
if [ -s ids_zruseno_$cp_date.txt ];
then 
    echo "Vypadá to, že některé schránky byly zrušené."
    echo "Jejich seznam je uveden v souboru ${b}ids_zruseno_$cp_date.txt${n}"
    sed -i "s/\t/\tSchránka zrušená?<br>V exportu ČP $cp_date chybí./" ids_zruseno_$cp_date.txt
else
    rm ids_zruseno_$cp_date.txt
fi

# přibyly schránky?
join -t$'\t' -v 1 cpost_crude_dedup.txt cp_ref_ids.txt | cut -f1 | sed "s/$/\tcp\:$cp_date/" > ids_nove_$cp_date.txt
if [ -s ids_nove_$cp_date.txt ];
then 
    echo "Vypadá to, že některé schránky přibyly."
    echo "Jejich seznam je uveden v souboru ${b}ids_nove_$cp_date.txt${n}"
else
    rm ids_nove_$cp_date.txt
fi

# přibyly dny výběru, které nejsou v konverzní tabulce?
if [ -s cp_konvertovat.txt ]
    then 
        echo "Vytvořen soubor ${b}cp_konvertovat.txt${n}, je třeba převést v programu ${b}EasyTransform${n}"
else
    rm cp_konvertovat.txt	# není potřeba, smazat
fi

# depa, soubor stačí jednorázově
#./datamash rmdup 2 < cpost_crude_dedup.txt | cut -f2-3 > cpost_Depa.txt

echo
echo "Pokračuji sloučením doby výběru ..."


# dny: dedup dní, porovnat s konv. tabulkou, vyhodit rozdíly
./datamash rmdup 13 < cpost_ps.csv |	# všechny hodnoty dní výběru
    cut -f13 | sort | dos2unix |	# jen dny výběru, setřídit, \r\n na \n
    join -t$'\t' -v1 - cp_ref_dny_konverze.txt > cpost_dny.txt	# vyhodit rozdíly oproti konverzní tabulce

# přibyly dny výběru, které nejsou v konverzní tabulce?
if [ -s cpost_dny.txt ]
then 
    echo "Přibyly dny výběru, je třeba ručně doplnit do konverzní tabulky v souboru ${b}cp_ref_dny_konverze.txt${n}"
    echo "Rozdíly jsou uvedené v souboru ${b}cpost_dny.txt${n}"
    echo "Skript se ukončí, po doplnění do konverzní tabulky je třeba ho opakovat."
    exit 
else
    rm cpost_dny.txt	# vymazat, není třeba
fi

echo "Pokračuji slučováním dní..."
echo

# nahrazení dní: zálohovat historii, sloučit, vyhodit změny, přepsat historii
# cat protože cp na jednom z počítačů nefunguje :
cat cp_ref_id_collection_time_history.txt > cp_ref_id_collection_time_history.bak 
./datamash groupby 1,13 collapse 12 < cpost_ps.csv |	# seskupit podle ref, dní výběru, spojit časy
    sort -k 2 | dos2unix |	# setřídit pro join s konverzí
    join -t$'\t' -1 2 -2 1 -o 1.1,2.2 1.3 - cp_ref_dny_konverze.txt |	# konverze dní
    sed 's/\t\(.*\)\t/\t\1 /' | sort -k 1 |	# spojení den + časy výběru
./datamash groupby 1 collapse 2 | dos2unix |	# seskupit ref, spojit dny výběru
    sed 's/,\(.. \|..-\)/; \1/g' |	# nahradit čárky středníky mezi dny výběru
    tee cpost_id_collection_time.txt |	# vypsat všechny časy výběru
    comm -3 - cp_ref_id_collection_time_history.txt > cpost_id_collection_time_changed.txt	# změnový soubor

# změny?
if [ -s cpost_id_collection_time_changed.txt ]
then 
    sed -i "s/$/\t$cp_date/" cpost_id_collection_time_changed.txt	# doplnit sloupec s datem (tředa jako source:collection_times=cp:datum)
    echo "Došlo ke změnám či doplnění doby výběru u některých schránek, je třeba aktualizovat v OSM datech."
    echo "Změnový soubor je ${b}cpost_id_collection_time_changed.txt${n}"
else
    echo "V datech výběru nebyly nalezeny změny."
    rm cpost_id_collection_time_changed.txt	# vymazat, není třeba
fi
# přepsat historii novými časy
cat cpost_id_collection_time.txt > cp_ref_id_collection_time_history.txt

# souřadnice schránek

echo "Vytvářím soubory pro geokodovaní"
# soubory pro geokodovani: kompletní + jen adresy
echo "Address" > cpost_NoCoord_Geocode.csv	# hlavička csv
./datamash -g 1 first 5,8-11 < cpost_crude_dedup.txt |	# ref + adresní pole
    dos2unix | 
    awk -F$'\t' '{ if($2) {print $1"\t"$2"\t"$3";"$4";"$5";"$6 } else {print $1"\t"$3"\t"$4";"$5";"$6 }}' |	# pole 2 nebo 3
    sed 's/\;\+/\;/g;s/\;$//' |	# další pole jako poznámka 
    sed -r 's/ /xxx/g; s/(\w+)\;+\1/\1/g ; s/xxx/ /g; s/\;/, /g' |	# vymazat opakovaná slova
    tee cpost_Adr.txt |	# ref + adresy
    join -t$'\t' -j 1 -v 2 cp_ref_coord_history.txt - |	# rozdíly oproti historii souřadnic
	tee cpost_NoCoord.bak	| # skutečné rozdíly
	join -t$'\t' -v 2 -j 1 cp_ref_coord_geocoded.txt - |	# vynech už jednou geokodované
    sort > cpost_NoCoord.txt.bak 	# ref + adresa pro geokodovani, setřídění neškodí
	cat sBSGC_ROOFTOP.txt sBSGC_GEOMETRIC_CENTER.txt | 	# z nějakého předchozího kódování, pro jistotu odečteme
	cut -f1 | sort | join -t$'\t' -j 1 -v 1 cpost_NoCoord.txt.bak - |
	tee cpost_NoCoord.txt |	# odečtené soubory připravené pro JOSM
    grep "(" | awk -F"[()]" ' { print $1$3"\t"$2} ' | 	# se závorkami, zkusíme upravit
	tee tst.txt | cut -f-2 | paste -d' ' - <( cut -f3- tst.txt ) | 
	sed 's/ \+/ /g' | awk -F"\t" '{ print $1"\",\""$2"\","$3 }' > GC_zavorky.csv
	
	grep -v "(" cpost_NoCoord.txt |	# zbytek, můžeme zkusit něco dalšího
	sed "s/\-*[uU] autobusové zastávky,* *//; s/[ -]*BUS zastávka//; s/[na ]*BUS zast.// ; s/[na ]*zastávce FTL//; s/na zdi vedle//; s/stojan zast.BUS//; s/na aut.zastávce//; s/aut.\s*zastávka//; s/\bstojan.*\b//; s/BUS zastávka//; s/,\t/\t/" | 
	awk -F"\t" '{ print $1"\",\""$2", "$3"\"" }' > GC_po_upravach.csv
	
# závěrečné spojení souborů
	echo "ref,Address" | 
		cat - GC_zavorky.csv GC_po_upravach.csv |
		sed "s/,\"*$//" > cpost_NoCoord_Geocode.csv
	
	rm tst.txt	# ukliď po sobě

echo
echo "Vytvořen soubor ${b}cpost_NoCoord.txt${n}"
echo "Vytvořen soubor ${b}cpost_NoCoord_Geocode.csv${n},"
echo "určený pro python skript" 



# není třeba konverze z Křováka:

if [ ! -f cp_konvertovat.txt ];
then
    echo -e "ref\tlatitude\tlongitude\tnote\tamenity\toperator\tsource" > "OUTPUT_$cp_date.txt"	# hlavička
    echo
    echo "Všechny souřadnice jsou v konverzní tabulce, můžu pokračovat..."
    echo 
    join -t$'\t' cp_ref_coord_history.txt cpost_Adr.txt |	# zkombinuj souř. + adresu
        cut -f1,4,5,7 |	# ořež pole
        join -t$'\t' - cpost_id_collection_time.txt |	# připoj dobu výběru
        sed "s/$/\tpost_box\tČeská pošta s.p.\tcp:$cp_date/" >> "OUTPUT_$cp_date.txt"	# přidej amenity,operator,source
    echo 
    echo "Hotovo."
    echo "Výsledek je v souboru ${b}OUTPUT_$cp_date.txt${n}"
    echo
    echo "Případné chyby vstupu jsou v souboru ${b}cpost_err.csv${n}"
else
    echo "Je třeba pokračovat konverzí, soubor cp_konvertovat.txt je připraven pro program EasyTransform"
fi


# vyčištění nepotřebných souborů
# rm cpost_crude_dedup.txt
# rm cpost_ps.csv

# ... další nedoděláno, po běhu programu zbývají další soubory pro pokračování příště ...
#
