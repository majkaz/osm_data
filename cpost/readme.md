# zpracování souboru české pošty

vyžaduje datamash ve stejném adresáři

znovu využívá referenční soubory:
	historie souřadnic vč. konverze: cp_ref_coord_history.txt 
	konverze dní výběru do OSM formátu: cp_ref_dny_konverze.txt
	historie collection_time: cp_ref_id_collection_time_history.txt

volání:
	cp.sh POST_SCHRANKY_<RRRRMM>.csv
