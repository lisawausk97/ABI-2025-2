nextflow.enable.dsl = 2

process downloadFile {
	publishDir "/home/lisawausk/ABI-2025-2/fastaexample/", mode: "copy", overwrite: true
	output: 
		path "batch1.fasta"
	"""
	wget https://tinyurl.com/cqbatch1 -O batch1.fasta
	"""
}

process countSeqs {
	publishDir "/home/lisawausk/ABI-2025-2/fastaexample/", mode: "copy", overwrite: true
	input:
		path fastafile
	output: 
		path "numseqs.txt"
	"""
	grep ">" ${fastafile} | wc -l > numseqs.txt
	"""
}

process splitSeq {
	publishDir "/home/lisawausk/ABI-2025-2/fastaexample/", mode: "copy", overwrite: true
	input:
		path inputfile
	output:
		path "Sequence_0*"
"""
split -l 2 -d --additional-suffix .fasta ${inputfile} Sequence_
"""
}

workflow {
	downloadChannel = downloadFile()
	countSeqs(downloadChannel)
	splitSeq(downloadChannel)
}
