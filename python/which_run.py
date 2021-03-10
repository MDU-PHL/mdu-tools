#!/usr/bin/env python3
import os
import argparse
import logging
import json


def create_logger(logging, tool_name, level):
    """
    A function to create a logger.
    """
    logger = logging.getLogger(tool_name)

    # Create handlers
    handler = logging.StreamHandler()
    handler.setLevel(level)

    # Create formatters and add it to handlers
    logformat = logging.Formatter(
        '[%(name)s - %(asctime)s] %(levelname)s: %(message)s')
    handler.setFormatter(logformat)

    # Add handlers to the logger
    logger.addHandler(handler)
    logger.setLevel(level)

    return logger
db_dict = {}
db_path = "/home/jianszhang/database/WR_DB"
logger = None

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--id", '-i', help="Checking the RUN ID for a MDU-ID")
	parser.add_argument("--idfile", help="Checking a list of MDU-IDs in a txt file")
	parser.add_argument("--output", "-o", help="output report to a tsv")
	parser.add_argument("--update-db-all", help="re-create all id db", action="store_true")
	parser.add_argument("--update-db-quick", help="only check the recent update locations", action="store_true")
	args = parser.parse_args()
	global logger
	logger = create_logger(logging, "which-run", logging.INFO)
	if args.update_db_all:
		update_db("all")
	if args.update_db_quick:
		update_db("quick")
	if args.id != None:
		if len(db_dict) == 0:
			read_db_from_json()
			logger.info("**DB loaded successfully**")
		info = args.id.strip().split("-")
		if len(info) < 2:
			logger.info(f"Could not find {args.id} in db")
		else:
			group = info[0]
			group_dict = db_dict.get(group, {})
			if len(group_dict) == 0:
				logger.info(f"Could not find {args.id} in db")
			else:
				record = group_dict.get(args.id, [])
				if len(record) == 0:
					logger.info(f"Could not find {args.id} in db")
				else:
					logger.info("Outputing results:")
					print("\t".join(["MDU-ID", "RUN-ID", "DATE", "PATH"]))
					for r in record:
						print("\t".join([args.id] + r))
	if args.idfile != None:
		if len(db_dict) == 0:
			read_db_from_json()
			logger.info("**DB loaded successfully**")
		if os.path.exists(args.idfile):
			file_flag = False
			if args.output:
				try:
					my_output = open(args.output, 'w')
					file_flag = True
				except:
					logger.error(f"Could not write into {args.output}, which run will print screan instead")
					file_flag = False
			title = ["MDU-ID", "RUN-ID", "DATE", "PATH"]
			if file_flag:
				my_output.write("\t".join(title) + "\n")
			else:
				print("\t".join(title))
			with open(args.idfile, 'r') as myfile:
				for line in myfile:
					m_id = line.strip()
					info = m_id.split("-")
					if len(info) < 2:
						logger.info(f"Could not find {m_id} in db")
						if file_flag:
							my_output.write("\t".join([m_id, "Not Found", "N/A", "N/A"]) + "\n")
						else:
							print("\t".join([m_id, "Not Found", "N/A", "N/A"]))
					else:
						group = info[0]
						group_dict = db_dict.get(group, {})
						if len(group_dict) == 0:
							logger.info(f"Could not find {m_id} in db")
							if file_flag:
								my_output.write("\t".join([m_id, "Not Found", "N/A", "N/A"]) + "\n")
							else:
								print("\t".join([m_id, "Not Found", "N/A", "N/A"]))
						else:
							record = group_dict.get(m_id, [])
							if len(record) == 0:
								logger.info(f"Could not find {m_id} in db")
								if file_flag:
									my_output.write("\t".join([m_id, "Not Found", "N/A", "N/A"]) + "\n")
								else:
									print("\t".join([m_id, "Not Found", "N/A", "N/A"]))
							else:
								#logger.info("Outputing results:")
								#print("\t".join(["MDU-ID", "RUN-ID", "DATE", "PATH"]))
								for r in record:
									if file_flag:
										my_output.write("\t".join([m_id] + r) + "\n")
									else:
										print("\t".join([m_id] + r))
			if file_flag:
				my_output.close()
		else:
			logger.error(f"Could not find {args.idfile}, which run terminated")


def save_db_to_json():
	db_json_file = os.path.join(db_path, "wr_db.json")
	with open(db_json_file, 'w') as json_file:
		json.dump(db_dict, json_file)

def read_db_from_json():
	global db_dict
	db_json_file = os.path.join(db_path, "wr_db.json")
	with open(db_json_file, 'r') as f:
		db_dict = json.load(f)

def is_qc_folder(path):
	if os.path.isdir(path):
		folder_name = path.split("/")[-1]
		if len(folder_name.split("_")) >= 4:
			return True
		else:
			return False
	else:
		return False

def check_samplesheet(path):
	for file in os.listdir(path):
		if file == "SampleSheet.csv" or file == "sample_sheet.csv":
			read_samplesheet(os.path.join(path, file))
			break
		else:
			continue
	return

def read_samplesheet(samplesheet):
	with open(samplesheet, 'r') as myfile:
		data_start = False
		run_id = ""
		date = ""
		global db_dict
		path = "/".join(samplesheet.split("/")[:-1])
		for line in myfile:
			if data_start == False:
				info = line.strip().split(",")
				if info[0] == "Experiment Name":
					run_id = info[1]
				if info[0] == "Date":
					date = info[1]
				if info[0] == "Sample_ID":
					data_start = True
			else:
				MDU_ID = line.strip().split(",")[0]
				group = MDU_ID.split("-")[0]
				my_group_dict = db_dict.get(group, {})
				my_record_list = my_group_dict.get(MDU_ID, [])
				repeat_flag = False
				for record in my_record_list:
					if record[0] == run_id:
						repeat_flag = True
						break
				if repeat_flag != True:
					my_record_list.append([run_id, date, path])
					my_group_dict[MDU_ID] = my_record_list
					db_dict[group] = my_group_dict
	return

def update_db(type):
	new_qc_path = "/home/mdu/instruments"
	for folder in os.listdir(new_qc_path):
		if os.path.isdir(os.path.join(new_qc_path, folder)):
			for mfile in os.listdir(os.path.join(new_qc_path, folder)):
				if is_qc_folder(os.path.join(new_qc_path, folder, mfile)):
					logger.info(f"**Checking {os.path.join(new_qc_path, folder, mfile)} folder**")
					check_samplesheet(os.path.join(new_qc_path, folder, mfile))
	logger.info("**New QC path checked**")
	qc_path = "/home/seq/MDU/incoming/bcl/nextseq"
	#check qc_path
	for myfile in os.listdir(qc_path):
		if is_qc_folder(os.path.join(qc_path, myfile)):
			logger.info(f"**Checking {myfile} folder**")
			check_samplesheet(os.path.join(qc_path, myfile))
	logger.info("**QC path checked**")
	#check iseq_path
	for myfile in os.listdir(os.path.join(qc_path, "iSEQ")):
		if is_qc_folder(os.path.join(qc_path, "iSEQ", myfile)):
			logger.info(f"**Checking {myfile} folder**")
			check_samplesheet(os.path.join(qc_path, "iSEQ", myfile))
	logger.info("**iSEQ path checked**")
	#check next500_path
	for myfile in os.listdir(os.path.join(qc_path, "NextSeq500")):
		if is_qc_folder(os.path.join(qc_path, "NextSeq500", myfile)):
			logger.info(f"**Checking {myfile} folder**")
			check_samplesheet(os.path.join(qc_path, "NextSeq500", myfile))
	logger.info("**NextSeq500 path checked**")
	#check next500 and next
	new_path = os.path.join(qc_path, "NextSeq500", "nextseq")
	for myfile in os.listdir(new_path):
		if is_qc_folder(os.path.join(new_path, myfile)):
			logger.info(f"**Checking {myfile} folder**")
			check_samplesheet(os.path.join(new_path, myfile))
	logger.info("**NextSeq500/next path checked**")
        #check next550 path
	new_path = os.path.join(qc_path, "NextSeq550", "nextseq")
	for myfile in os.listdir(new_path):
		if is_qc_folder(os.path.join(new_path, myfile)):
			logger.info(f"**Checking {myfile} folder**")
			check_samplesheet(os.path.join(new_path, myfile))
	logger.info("**NextSeq550/next path checked**")
	if type == "all":
		#check old years folder
		logger.info("**Checking historic records**")
		for year in ["2016", "2017", "2018", "2019", "2020","2021"]:
			logger.info(f"**Checking {year} historic records**")
			for folder in os.listdir(os.path.join(qc_path, year)):
				if os.path.isdir(os.path.join(qc_path, year, folder)):
					for myfile in os.listdir(os.path.join(qc_path, year, folder)):
						if is_qc_folder(os.path.join(qc_path, year, folder, myfile)):
							logger.info(f"**Checking {myfile} folder**")
							check_samplesheet(os.path.join(qc_path, year, folder, myfile))
	logger.info("**DB update finished, saving changes to db json file**")
	save_db_to_json()
	return


if __name__ == "__main__":
	main()


