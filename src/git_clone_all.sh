#/usr/bin/env bash

# git clone steps
# ---------------

git clone	git@github.com:datagovuk/ckan 
cd ckan
git checkout release-v1.7.1-dgu
cd -

git clone	git@github.com:datagovuk/ckanext-archiver 
cd ckanext-archiver
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-datapreview 
cd ckanext-datapreview
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-dgu 
cd ckanext-dgu
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-ga-report 
cd ckanext-ga-report
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-harvest 
cd ckanext-harvest
git checkout dgu
cd -

git clone	git@github.com:datagovuk/ckanext-os 
cd ckanext-os
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-qa 
cd ckanext-qa
git checkout temp_working
cd -

git clone	git@github.com:okfn/ckanext-social 
cd ckanext-social
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-spatial 
cd ckanext-spatial
git checkout dgu
cd -
