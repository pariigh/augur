Setup

  $ export AUGUR="${AUGUR:-$TESTDIR/../../../../bin/augur}"
  $ export SCRIPTS="$TESTDIR/../../../../scripts"
  $ export ANC_DATA="$TESTDIR/../../ancestral/data/simple-genome"
  $ export DATA="$TESTDIR/../data/simple-genome"

This test is similar to the main `vcf.t` test, however here we introduce a
mutation at the root by modifying the VCF file to include a G20A mutation for
every sample (i.e. including internal nodes). This introduces a G4E AA change in
gene1 which should be described as a mutation on the root of the tree (relative
to the provided reference.fasta)

  $ sed '10s/^/1\t20\t.\tG\tA\t.\t.\t.\tGT\t1\t1\t1\t1\t1\n/' \
  >   "$DATA/snps-inferred.vcf"  > input.vcf

  $ ${AUGUR} translate \
  >  --tree "$ANC_DATA/tree.nwk" \
  >  --ancestral-sequences input.vcf \
  >  --reference-sequence "$DATA/reference.gff" \
  >  --output-node-data "aa_muts.json" \
  >  --alignment-output aa_muts.vcf \
  >  --vcf-reference "$ANC_DATA/reference.fasta" \
  >  --vcf-reference-output reference.fasta
  Read in 3 features from reference sequence file
  amino acid mutations written to aa_muts.json

The _reference_ produced is the actual reference, not using the mutations in the tree
(I.e. it's the _parent_ of the tree root, not the actual root)
  $ cat reference.fasta
  >gene1
  MPCG*
  >gene2
  MVK* (no-eol)

However the aa_mutations should annotate the aa_sequence on the root node as
having the G3E AA mutation, i.e. MPCE* instead of MPCG*, as well as a
corresponding AA mutation on the root node G4E (i.e. reference is G, but root
node is E (and so are all the other nodes))

  $ sed '46s/MPCG/MPCE/' "$DATA/aa_muts.json" |  sed '42s/\[\]/\["G4E"\]/' > aa_muts.truth.json

  $ python3 "$SCRIPTS/diff_jsons.py" \
  >   aa_muts.truth.json \
  >   aa_muts.json \
  >   --exclude-regex-paths "root\['annotations'\]\['.+'\]\['seqid'\]" "root['meta']['updated']"
  {}