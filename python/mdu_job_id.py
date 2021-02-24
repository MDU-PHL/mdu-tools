#!/usr/bin/env python3
import os
import argparse
import subprocess
import glob
from xml.dom import minidom
import datetime

def later_time(num_of_minutes):
	now = datetime.datetime.now()
	plus_time = now + datetime.timedelta(minutes = num_of_minutes)
	return plus_time.strftime("%m/%d/%Y, %H:%M:%S")

def bash_command(cmd):
	p = subprocess.Popen(cmd, shell=True)
	while True:
		return_code = p.poll()
		if return_code is not None:
			break
	return

def get_run_id(xml_file):
		mydoc = minidom.parse(xml_file)
		id_item = mydoc.getElementsByTagName("ExperimentName")[0]
		return id_item.firstChild.data

def is_qc_folder(path):
	if os.path.isdir(path):
		folder_name = path.split("/")[-1]
		if len(folder_name.split("_")) >= 4:
			return True
		else:
			return False
	else:
		return False

def check_job_id(job_id, folder):
	m_path = os.path.join(folder, "RunParameters.xml")
	if os.path.exists(m_path):
		return job_id == get_run_id(m_path)
	else:
		return False

def found_notif(job_id, m_path, found=True):
	if found:
		print(f"{job_id} found, which is/was running in {m_path}")
	else:
		print(f"Could not find {job_id} in all QC paths")


def find_run(job_id):
	seq_path = "/home/seq/MDU/incoming/bcl/nextseq"
	normal_folder = ["NextSeq500", "NextSeq550", "iSEQ"]
	#check_recent
	#base qc folder
	for mfile in os.listdir(seq_path):
		if is_qc_folder(os.path.join(seq_path,mfile)):
			m_path = os.path.join(seq_path, mfile)
			if check_job_id(job_id, m_path):
				found_notif(job_id, m_path)
				return m_path
	#normal folder
	for folder in normal_folder:
		for mfile in os.listdir(os.path.join(seq_path, folder)):
			if mfile == "nextseq":
				for xfile in os.listdir(os.path.join(seq_path, folder, mfile)):
					if is_qc_folder(os.path.join(seq_path, folder, mfile, xfile)):
						m_path = os.path.join(seq_path, folder, mfile, xfile)
						if check_job_id(job_id, m_path):
							found_notif(job_id, m_path)
							return m_path
			elif is_qc_folder(os.path.join(seq_path, folder, mfile)):
				m_path = os.path.join(seq_path, folder, mfile)
				if check_job_id(job_id, m_path):
					found_notif(job_id, m_path)
					return m_path
	#check_history_folder
	for year in ["2016", "2017", "2018", "2019", "2020", "2021"]:
		for folder in os.listdir(os.path.join(seq_path, year)):
			if os.path.isdir(os.path.join(seq_path, year, folder)):
				for myfile in os.listdir(os.path.join(seq_path, year, folder)):
					if is_qc_folder(os.path.join(seq_path, year, folder, myfile)):
						m_path = os.path.join(seq_path, year, folder, myfile)
						if check_job_id(job_id, m_path):
							found_notif(job_id, m_path)
							return m_path
	found_notif(job_id, m_path, False)
	return ""

def basecall_line(b_path):
	list_of_files = []
	for mfile in os.listdir(b_path):
		list_of_files.append(os.path.join(b_path, mfile))
	lastest_file = max(list_of_files, key=os.path.getctime)
	#print(lastest_file)
	num_of_bcl = 0
	#print(lastest_file.split("/")["-1"].split(".")[0])
	try:
		num_of_bcl = int(lastest_file.split("/")[-1].split(".")[0])
	except:
		num_of_bcl = 0
	return num_of_bcl

def notif_progress(num_of_bcl, job_id, L_num = 0):
	if L_num == 0:
		print(f"**iSEQ is Running, Job Id : {job_id}**")
		print(f"**Current {num_of_bcl} out of 318 have been done, approximate {(318 -num_of_bcl)*2} minutes left**")
		print(f"**May finish on {later_time((318 -num_of_bcl)*2)}**")
	else:
		print(f"**NextSeq is Running, Job Id : {job_id}**")
		print(f"**Current {num_of_bcl} out of 318  have been done**")
		print(f"**approximate {(318 - num_of_bcl)*4} minutes left, may finish on {later_time((318 - num_of_bcl)*4)}**")

def check_progress(job_id, m_path):
	if os.path.exists(os.path.join(m_path, job_id)):
		print("sequence run finished")
	elif os.path.exists(os.path.join(m_path, "Data", "Intensities", "BaseCalls")):
		if "iSEQ" in os.path.abspath(m_path):
			num_of_bcl = basecall_line(os.path.join(m_path, "Data", "Intensities", "BaseCalls", "L001"))
			notif_progress(num_of_bcl, job_id)
		else:
			list_of_folder = os.listdir(os.path.join(m_path, "Data", "Intensities", "BaseCalls"))
			most_L = sorted(list_of_folder)[-1]
			L_num = int(most_L[-1])
			num_of_bcl = basecall_line(os.path.join(m_path, "Data", "Intensities", "BaseCalls", most_L))
			notif_progress(num_of_bcl, job_id, L_num)
	else:
		print("sequence has not been started")

def job_id_format(job_id):
	if job_id[0] == "M":
		try:
			year = int(job_id[1:5])
		except:
			return False
		try:
			mid = int(job_id.split("-")[-1])
		except:
			return False
		return True
	return False

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-j", "--job_id", help = "search the running folder of MDU JOB ID and check the sequence running progress")
	parser.add_argument("-p", "--path", help = "Show the MDU JOB ID of the path and check the sequence running progress")
	args = parser.parse_args()
	if args.job_id == None and args.path == None:
		print("Please provide either job id or the path")
	elif args.job_id != None and args.path != None:
		print("Please only provide one of the parameters, either job id or the path")
	elif args.job_id != None:
		if job_id_format(args.job_id):
			m_path = find_run(args.job_id)
			if m_path != "":
				check_progress(args.job_id, m_path)
		else:
			print("Please check your Job ID format, it should look like MXXXX-XXXXX")
	else:
		if os.path.exists(args.path):
			if os.path.exists(os.path.join(args.path, "RunParameters.xml")):
				job_id = get_run_id(os.path.join(args.path, "RunParameters.xml"))
				check_progress(job_id, args.path)
		else:
			print("Could not find {args.path}, please check if it exists")

if __name__ == "__main__":
	main()

