#!/bin/bash
# on my system, $ perl -v:
# This is perl, v5.10.0 built for darwin-thread-multi-2level
# (with 2 registered patches, see perl -V for more detail)
PERL=perl

# $ phyml -version
# PhyML v3.0_360-500M 
PHYML=phyml

# http://users.iab.uaf.edu/~derek_sikes/software2.htm
PAUPRAT=pauprat

# $ paup -v
# P A U P *
# Portable version 4.0b10 for Unix
PAUP=paup

# $ muscle -version
# MUSCLE v3.6 by Robert C. Edgar
MUSCLE=muscle

# http://www.evolution.rdg.ac.uk/Files/BayesTraits-OSX-Intel-V1.0.tar.gz
BAYESTRAITS=BayesTraits

HYPHY_DIR=/Users/rvosa/Applications/hyphy1/hyphy/HYPHY/
HYPHY="$HYPHY_DIR/HYPHY"

# project variables
DATA=data
RAWDATA=$DATA/raw/
TAXAMAP=$DATA/excel/taxa.csv
SPECIESPHYLOXML=$DATA/speciestree.phyloxml
SOURCETREES=$DATA/sourcetrees/
LOGFILE=err.log

# these are the data from Nick, with some edits recorded on github
FASTAFILES=`ls $RAWDATA/*.fas`
NEXUSTREES=`ls $RAWDATA/*.tre`

# variables for supertree
SUPERTREE=$DATA/supertree
SUPERMRPSTEM=MRP_matrix
SUPERMRP=$SUPERTREE/$SUPERMRPSTEM.nex
MRPOUTGROUP=mrp_outgroup
RATCHETSETUP=setup.nex
RATCHETCOMMANDS=ratchet.nex
RATCHETRESULT=$SUPERTREE/mydata.tre

# variables for NCBI taxonomy tree
NCBISTEM=phyliptree
NCBITREE=$DATA/$NCBISTEM.phy
NCBIMRP=$SOURCETREES/$NCBISTEM.dat

# this adds the map object Bio::Phylo::Cobra::TaxaMap to the
# perl class path
PERL5LIB="${PERL5LIB}:lib"

# here are the scripts
SCRIPT=script/

# convert fasta files to phylip files for phyml
for FASTAFILE in $FASTAFILES; do
    PHYLIPFILE=`echo $FASTAFILE | sed -e 's/.fas/.phylip/'`
    if [ ! -s "$PHYLIPFILE" ]; then
        echo "*** Converting $FASTAFILE to phylip" > $LOGFILE
        $PERL $SCRIPT/fas2phylip.pl -i $FASTAFILE -c $TAXAMAP > $PHYLIPFILE 2>> $LOGFILE
    fi
done

# rename tips in consensus trees, write out as newick
for NEXUSTREE in $NEXUSTREES; do
    NEWICKTREE=`echo $NEXUSTREE | sed -e 's/.tre/.dnd/'`
    if [ ! -s "$NEWICKTREE" ]; then
        echo "*** Creating newick tree $NEWICKTREE" >> $LOGFILE
        $PERL $SCRIPT/nexus2newick.pl -c $TAXAMAP -i $NEXUSTREE > $NEWICKTREE 2>> $LOGFILE
        
        # attach unique node labels
        $PERL -i $SCRIPT/nodelabels.pl $NEWICKTREE 2>> $LOGFILE
    fi
done

# run phyml on each phylip file
PHYLIPFILES=`ls $RAWDATA/*.phylip`
for PHYLIPFILE in $PHYLIPFILES; do
    NEWICKTREE=`echo $PHYLIPFILE | sed -e 's/.phylip/.dnd/'`
    if [ ! -s "${PHYLIPFILE}_phyml_tree.txt" ]; then
        echo "*** Running phyml on $PHYLIPFILE" >> $LOGFILE
        $PHYML -i $PHYLIPFILE -u $NEWICKTREE -s BEST 2>> $LOGFILE
    fi
done

# write phyml files to phyloxml
PHYMLSTEMS=`ls $RAWDATA/*.phylip_phyml_tree.txt | sed -e 's/.phylip_phyml_tree.txt//'`
for STEM in $PHYMLSTEMS; do
    if [ ! -s "$STEM.phyloxml" ]; then
        echo "*** Creating phyloxml file $STEM.phyloxml" >> $LOGFILE
        $PERL $SCRIPT/phyloxml.pl -s $STEM -f newick -c $TAXAMAP > $STEM.phyloxml 2>> $LOGFILE
    fi
done

# fetch NeXML files from TreeBASE
#$PERL $SCRIPT/fetch_trees.pl -d $SOURCETREES -c $TAXAMAP 2>> $LOGFILE

# write NeXML files to MRP matrices
NEXMLFILES=`ls $SOURCETREES/Tr*.xml`
for NEXML in $NEXMLFILES; do
    DAT=`echo $NEXML | sed -e 's/.xml/.dat/'`
    if [ ! -s "$DAT" ]; then
        echo "*** Writing MRP matrix $DAT" >> $LOGFILE
        $PERL $SCRIPT/treebase2mrp.pl -i $NEXML -f nexml -c $TAXAMAP > $DAT 2>> $LOGFILE
    fi
done

# write NCBI tree to MRP matrix
if [ ! -s "$NCBIMRP" ]; then
    echo "*** Writing MRP matrix $NCBIMRP" >> $LOGFILE
    $PERL $SCRIPT/ncbi2mrp.pl -i $NCBITREE -f newick -c $TAXAMAP > $NCBIMRP 2>> $LOGFILE
fi

# concatenate MRP matrices to NEXUS file
if [ ! -s "$SUPERMRP" ]; then
    echo "*** Concatenating MRP matrices to $SUPERMRP" >> $LOGFILE
    $PERL $SCRIPT/concat_tables.pl -d $SOURCETREES -c $TAXAMAP -o $MRPOUTGROUP > $SUPERMRP 2>> $LOGFILE
fi

# write ratchet commands
if [ ! -s "$SUPERTREE/$RATCHETCOMMANDS" ]; then
    echo "*** Writing ratchet commands $RATCHETCOMMANDS" >> $LOGFILE
    cd $SUPERTREE
    $PAUPRAT $RATCHETSETUP 2>> $LOGFILE
    cd -
    $PERL $SCRIPT/make_ratchet_footer.pl \
        --constraint $NCBITREE \
        -f newick \
        -o $MRPOUTGROUP \
        --csv $TAXAMAP \
        -r $RATCHETCOMMANDS >> $SUPERMRP 2>> $LOGFILE
fi

# run paup with parsimony ratchet
if [ ! -s "$RATCHETRESULT" ]; then
    echo "*** Running parsimony ratchet" >> $LOGFILE
    cd $SUPERTREE
    $PAUP $SUPERMRPSTEM.nex 2>> $LOGFILE
    cd -
fi

# write consensus PHYLOXML tree over ratchet results
if [ ! -s "$SPECIESPHYLOXML" ]; then
    echo "*** Making consensus $SPECIESPHYLOXML" >> $LOGFILE
    $PERL $SCRIPT/make_consensus.pl -i $RATCHETRESULT -c $TAXAMAP -o $MRPOUTGROUP > $SPECIESPHYLOXML 2>> $LOGFILE
fi

# run SDI on gene trees
GENETREES=`ls $RAWDATA/*.phyloxml`
for GENETREE in $GENETREES; do
    SDITREE=`echo $GENETREE | sed -e 's/.phyloxml/_sdi.phyloxml/'`
    if [ ! -s "$SDITREE" ]; then
        echo "*** Running archeopteryx on $GENETREE" >> $LOGFILE
        
        # this requires that forester.jar is in the java class path
        # http://www.phylosoft.org/forester/download/forester.jar
        java org.forester.application.sdi $GENETREE $SPECIESPHYLOXML $SDITREE 2>> $LOGFILE
    fi
done

# fetch protein sequences from GenBank
#FASTAFILES=`ls $RAWDATA/*.fas`
#for FASTAFILE in $FASTAFILES; do
#    PROTFILE=`echo $FASTAFILE | sed -e 's/.fas/.prot/'`
#    if [ ! -s "$PROTFILE" ]; then
#        echo "*** Fetching data for $PROTFILE"
#        $PERL $SCRIPT/fetch_protein.pl -f fasta -i $FASTAFILE -t dna -c $TAXAMAP > $PROTFILE
#    fi
#done

# align protein sequences
#PROTFILES=`ls $RAWDATA/*.prot`
#for PROTFILE in $PROTFILES; do
#    ALN=`echo $PROTFILE | sed -e 's/.prot/.aln/'`
#    if [ ! -s "$ALN" ]; then
#        echo "*** Aligning $PROTFILE"
#        $MUSCLE -in $PROTFILE -out $ALN
#    fi
#done

# make nexus files containing codon alignment and ML tree
NEWICKTREES=`ls $RAWDATA/*.dnd`
for TREE in $NEWICKTREES; do
    DATA=`echo $TREE | sed -e 's/.dnd/.phylip/'`
    NEXUS=`echo $TREE | sed -e 's/.dnd/.nex/'`
    if [ ! -s "$NEXUS" ]; then
        echo "*** Making $NEXUS" >> $LOGFILE
        $PERL $SCRIPT/make_nexus.pl \
            --treefile=$TREE \
            --treeformat=newick \
            --datafile=$DATA \
            --dataformat=phylip \
            --datatype=dna > $NEXUS 2>> $LOGFILE
    fi
done

# make hyphy scripts
#NEXUSFILES=`ls $RAWDATA/*.nex`
#CWD=`pwd`
#for NEXUS in $NEXUSFILES; do
#    HYPHYIN=`echo $NEXUS | sed -e 's/.nex/.hyphyin/'`
#    if [ ! -s "$HYPHYIN" ]; then
#        echo "*** Making hyphy script $HYPHYIN"
#        $PERL $SCRIPT/hyphywrapper.pl -i "$CWD/$NEXUS" > $HYPHYIN
#    fi
#done

# run hyphy
#HYPHYINS=`ls $RAWDATA/*.hyphyin`
#CWD=`pwd`
#for HYPHYIN in $HYPHYINS; do
#    HYPHYOUT=`echo $HYPHYIN | sed -e 's/.hyphyin/.hyphyout/'`
#    if [ ! -s "$HYPHYOUT" ]; then
#        echo "*** Running hyphy $HYPHYOUT"
#        $PERL $SCRIPT/runhyphy.pl --executable=$HYPHY --hyphydir=$HYPHY_DIR --infile="$CWD/$HYPHYIN" > $HYPHYOUT
#    fi
#done

# run bayestraits for each gene tree

# test branches with non_venom -> venom changes for dN/dS deviation
