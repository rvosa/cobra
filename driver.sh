#!/bin/bash
# I have these in my $PATH
PERL=perl
PHYML=phyml
PAUPRAT=pauprat
PAUP=paup
MUSCLE=muscle

# project variables
DATA=data
RAWDATA=$DATA/raw/
TAXAMAP=$DATA/excel/taxa.csv
SPECIESPHYLOXML=$DATA/speciestree.phyloxml
SOURCETREES=$DATA/sourcetrees/
LOGFILE=err.log

SUPERTREE=$DATA/supertree
SUPERMRPSTEM=MRP_matrix
SUPERMRP=$SUPERTREE/$SUPERMRPSTEM.nex
SUPERFOOTER=$SUPERTREE/${SUPERMRPSTEM}_footer.nex
MRPOUTGROUP=mrp_outgroup
RATCHETSETUP=setup.nex
RATCHETCOMMANDS=ratchet.nex
RATCHETRESULT=$SUPERTREE/mydata.tre

NCBISTEM=phyliptree
NCBITREE=$DATA/$NCBISTEM.phy
NCBIMRP=$SOURCETREES/$NCBISTEM.dat
PERL5LIB="${PERL5LIB}:lib"
SCRIPT=script/

# convert fasta files to phylip files for phyml
#FASTAFILES=`ls $RAWDATA/*.fas`
#for FASTAFILE in $FASTAFILES; do
#    PHYLIPFILE=`echo $FASTAFILE | sed -e 's/.fas/.phylip/'`
#    $PERL $SCRIPT/fas2phylip.pl -i $FASTAFILE -c $TAXAMAP > $PHYLIPFILE
#done

# add short PHYLIP names to table
#$PERL $SCRIPT/map_phylip_names.pl -d $RAWDATA -p phylip -f fas -c $TAXAMAP > $TAXAMAP.bak
#mv $TAXAMAP.bak $TAXAMAP

# rename tips in consensus trees, write out as newick
#NEXUSTREES=`ls $RAWDATA/*.tre`
#for NEXUSTREE in $NEXUSTREES; do
#    NEWICKTREE=`echo $NEXUSTREE | sed -e 's/.tre/.dnd/'`
#    $PERL $SCRIPT/nexus2newick.pl -c $TAXAMAP -i $NEXUSTREE > $NEWICKTREE
#done

# run phyml on each phylip file
#PHYLIPFILES=`ls $RAWDATA/*.phylip`
#for PHYLIPFILE in $PHYLIPFILES; do
#    NEWICKTREE=`echo $PHYLIPFILE | sed -e 's/.phylip/.dnd/'`
#    $PHYML -i $PHYLIPFILE -u $NEWICKTREE -s BEST
#done

# write phyml files to phyloxml
#PHYMLSTEMS=`ls $RAWDATA/*.phylip_phyml_tree.txt | sed -e 's/.phylip_phyml_tree.txt//'`
#for STEM in $PHYMLSTEMS; do
#    $PERL $SCRIPT/phyloxml.pl -s $STEM -f newick -c $TAXAMAP > $STEM.phyloxml
#done

# fetch NeXML files from TreeBASE
# perl $SCRIPT/fetch_trees.pl -d $SOURCETREES -c $TAXAMAP

# write NeXML files to MRP matrices
#NEXMLFILES=`ls $SOURCETREES/Tr*.xml`
#for NEXML in $NEXMLFILES; do
    #DAT=`echo $NEXML | sed -e 's/.xml/.dat/'`
    #$PERL $SCRIPT/treebase2mrp.pl -i $NEXML -f nexml -c $TAXAMAP > $DAT
#done

# write NCBI tree to MRP matrix
#$PERL $SCRIPT/ncbi2mrp.pl -i $NCBITREE -f newick -c $TAXAMAP > $NCBIMRP

# concatenate MRP matrices to NEXUS file
#$PERL $SCRIPT/concat_tables.pl -d $SOURCETREES -c $TAXAMAP -o $MRPOUTGROUP > $SUPERMRP

# write ratchet commands
#cd $SUPERTREE
#$PAUPRAT $RATCHETSETUP
#cd -

# append command block footer
#$PERL $SCRIPT/make_ratchet_footer.pl --constraint $NCBITREE -f newick -o $MRPOUTGROUP -r $RATCHETCOMMANDS >> $SUPERMRP

# run paup
#cd $SUPERTREE
#$PAUP $SUPERMRPSTEM.nex
#cd -

# write consensus PHYLOXML tree
#$PERL $SCRIPT/make_consensus.pl -i $RATCHETRESULT -c $TAXAMAP -o $MRPOUTGROUP > $SPECIESPHYLOXML

# fetch protein sequences from GenBank
#FASTAFILES=`ls $RAWDATA/*.fas`
#for FASTAFILE in $FASTAFILES; do
#    PROTFILE=`echo $FASTAFILE | sed -e 's/.fas/.prot/'`
#    $PERL $SCRIPT/fetch_protein.pl -f fasta -i $FASTAFILE -t dna -c $TAXAMAP > $PROTFILE
#done

# align protein sequences
#PROTFILES=`ls $RAWDATA/*.prot`
#for PROTFILE in $PROTFILES; do
#    ALN=`echo $PROTFILE | sed -e 's/.prot/.aln/'`
#    $MUSCLE -in $PROTFILE -out $ALN
#done