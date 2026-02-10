process GET_GLOBAL_MIN_LENGTH {

	cpus = { 1 * task.attempt }
	memory = { 2.GB * task.attempt }
	
	input:
	path(multiqc_raw_out)

	output:
	stdout emit: min_len

	script:
	"""
	#!/usr/bin/env python3
	import json
	import os

	json_path = os.path.join('${multiqc_raw_out}', 'multiqc_data.json')
    
	with open(json_path) as f:
		data = json.load(f)
    
	stats = data['report_general_stats_data']
	lengths = [list(read.values())[1] for read in stats[0].values()]
	
	print(int(min(lengths)), end='')
	"""
}

