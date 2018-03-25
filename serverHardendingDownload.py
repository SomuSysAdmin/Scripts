from bs4 import BeautifulSoup
import requests
import shutil
import os
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

#   Downloads the RedHat Certified System Administrator Course by Sander Van Vugt

url = 'https://www.safaribooksonline.com/library/view/linux-security-red/9780134598345/'
domain = 'https://www.safaribooksonline.com'
output_folder = './ServerHardening'
username = 'notMyRealEmail@gmail.com'
password = 'notMyRealPassword'
count=0

req = requests.get(url)
soup = BeautifulSoup(req.text, 'html.parser')

lessons = soup.find_all('li', class_='toc-level-1')
length = (len(lessons))
print("#!/bin/bash")

shutil.rmtree(output_folder, ignore_errors=True)
os.makedirs(output_folder)
module_name = 'Module 0'
hrefList = []
for lesson in lessons:
	lesson_name = lesson.a.text.strip().replace(':', ' - ')
	if lesson_name.startswith('Module') and not 'Summary' in lesson_name:
		module_name = lesson_name
		os.makedirs(output_folder + '/' + module_name)
		print(output_folder + '/' + module_name)
		# print(module_name)
		for index, video in enumerate(lesson.find_all('a')):
			video_name = str(index) + ' - ' + video.text.encode('utf-8').strip().replace(':','- ')
			video_url = domain + video.get('href')
			if video_url in hrefList:
				continue
			else:
				hrefList.append(video_url)
			video_out = output_folder + '/' + module_name + '/' + video_name + '.mp4'
			# print('        ', domain + video_url)
			command = ("youtube-dl -u {} -p {} --output '{}' {}".format(username, password, video_out, video_url))
			count+=1
			print('echo -e "\\n---------- Downloading file : {} ----------\\n"\n'.format(count))
			print("format=$( {} -F | grep '^mp4' | tail -n 2 | head -n 1 | awk '{{ print $1 }}')\n\n".format(command))
			print(" {} -f $format\n\n".format(command))

	else:
		os.makedirs(output_folder + '/' + module_name + '/' + lesson_name)
		# print('   ', lesson_name)
		for index, video in enumerate(lesson.find_all('a')):
			video_name = str(index) + ' - ' + video.text.strip().encode('utf-8').replace(':','- ')
			video_url = domain + video.get('href')
			if video_url in hrefList:
				continue
			else:
				hrefList.append(video_url)
			video_out = output_folder + '/' + module_name + '/' + lesson_name + '/' + video_name + '.mp4'
			# print('        ', domain + video_url)
			command = ("youtube-dl -u {} -p {} --output '{}' {}".format(username, password, video_out, video_url))
			count+=1
			print('echo -e "\\n---------- Downloading file : {} ----------\\n"\n'.format(count))
			print("format=$( {} -F | grep '^mp4' | tail -n 2 | head -n 1 | awk '{{ print $1 }}')\n".format(command))
			print(" {} -f $format\n\n".format(command))
