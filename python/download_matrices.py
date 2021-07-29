#!/usr/bin/env python3 
#-*- coding: utf-8 -*-

# The MIT License (MIT)
#
# Copyright (c) 2021 Alexander Samoilov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# `sudo pip3 install bs4` for BeautifulSoup

import re, os, requests, pathlib
from bs4 import BeautifulSoup
re_prefix = re.compile(r"(^[^\d\W]\w*\s*):\s*(http://.*|https://.*)", re.UNICODE)

def parse(dic, line):
    # match regexp `id: url`
    # url starts from `http://` or `https://`
    result = re.match(re_prefix, line)
    if result is not None:
        dic[result[1]] = result[2]

def listFD(url, attrs):
    page = requests.get(url).text
    soup = BeautifulSoup(page, 'html.parser')
    return soup.find_all('a', attrs=attrs)

def download_matrix(download_url, file_name):
    r = requests.get(download_url, allow_redirects=True)
    with open(file_name, 'wb') as f:
        f.write(r.content)

if __name__ == '__main__':
    path = 'link.txt'
    dic = {}
    with open(path, 'r') as f:
        for line in f:
            parse(dic, line)

    attrs = {
        'href': re.compile(r'\.tar.gz$')
    }
    for k, v in dic.items():
        # mkdir for k
        if not os.path.exists(k):
            os.makedirs(k)

        files = listFD(v, attrs)
        for fname in files:
            download_url = fname['href']
            path, file = os.path.split(download_url)
            dirs = path.split(os.sep)
            matrix_type_dir = dirs[:-1][-1]
            write_path = pathlib.PurePath(k, matrix_type_dir)
            if not os.path.exists(write_path):
                os.makedirs(write_path)

            file_to_save = pathlib.PurePath(write_path, file)
            print('downloading matrix ', file, ' from url ', download_url)
            print('and saving to ', file_to_save)
            download_matrix(download_url, file_to_save)
