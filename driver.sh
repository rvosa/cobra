#!/bin/bash
PERL=perl
PHYML=phyml
PAUPRAT=pauprat
DATA=data
RAWDATA=$DATA/raw/
TAXAMAP=$DATA/excel/taxa.csv
SOURCETREES=$DATA/sourcetrees/
SUPERTREE=$DATA/supertree
SUPERMRP=$SUPERTREE/MRP_matrix.nex
SUPERFOOTER=$SUPERTREE/MRP_matrix_footer.nex
RATCHETSETUP=setup.nex
NCBISTEM=phyliptree
NCBITREE=$DATA/$NCBISTEM.phy
NCBIMRP=$SOURCETREES/$NCBISTEM.dat
PERL5LIB="${PERL5LIB}:lib"
SCRIPT=script/

# convert fasta files to phylip files for phyml
# FASTAFILES=`ls $RAWDATA/*.fas`
# for FASTAFILE in $FASTAFILES; do
#     PHYLIPFILE=`echo $FASTAFILE | sed -e 's/.fas/.phylip/'`
#     $PERL $SCRIPT/fas2phylip.pl -i $FASTAFILE -c $TAXAMAP > $PHYLIPFILE
# done

# run phyml on each phylip file
# PHYLIPFILES=`ls $RAWDATA/*.phylip`
# for PHYLIPFILE in $PHYLIPFILES; do
#     $PHYML -i $PHYLIPFILE
# done

# write phyml files to phyloxml
# PHYMLSTEMS=`ls $RAWDATA/*.phylip_phyml_tree.txt | sed -e 's/.phylip_phyml_tree.txt//'`
# for STEM in $PHYMLSTEMS; do
#     $PERL $SCRIPT/phyloxml.pl -s $STEM -f newick -c $TAXAMAP > $STEM.phyloxml
# done

# fetch NeXML files from TreeBASE
# perl $SCRIPT/fetch_trees.pl -d $SOURCETREES -c $TAXAMAP

# write NeXML files to MRP matrices
# NEXMLFILES=`ls $SOURCETREES/Tr*.xml`
# for NEXML in $NEXMLFILES; do
#     DAT=`echo $NEXML | sed -e 's/.xml/.dat/'`
#     $PERL $SCRIPT/treebase2mrp.pl -i $NEXML -f nexml -c $TAXAMAP > $DAT
# done

# write NCBI tree to MRP matrix
# $PERL $SCRIPT/ncbi2mrp.pl -i $NCBITREE -f newick -c $TAXAMAP > $NCBIMRP

# concatenate MRP matrices to NEXUS file
$PERL $SCRIPT/concat_tables.pl -d $SOURCETREES -c $TAXAMAP > $SUPERMRP

# append command block footer
cat $SUPERFOOTER >> $SUPERMRP

# write ratchet commands
cd $SUPERTREE
$PAUPRAT $RATCHETSETUP
cd -