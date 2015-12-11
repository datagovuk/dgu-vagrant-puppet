#/usr/bin/env bash

# git clone steps
# ---------------

git clone	https://github.com/datagovuk/ckan
cd ckan
git checkout release-v2.2-dgu
git remote add okfn https://github.com/okfn/ckan
cd -

git clone	https://github.com/datagovuk/ckanext-archiver
cd ckanext-archiver
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-certificates
cd ckanext-certificates
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-datapreview
cd ckanext-datapreview
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-dcat
cd ckanext-dcat
git checkout dgu
cd -

git clone	https://github.com/datagovuk/ckanext-dgu
cd ckanext-dgu
git checkout master
ln -s ../commit-msg.githook ./.git/hooks/commit-msg
cd -

git clone	https://github.com/datagovuk/ckanext-dgu-local
cd ckanext-dgu-local
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-ga-report
cd ckanext-ga-report
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-harvest
cd ckanext-harvest
git checkout 2.0
cd -

git clone	https://github.com/datagovuk/ckanext-hierarchy
cd ckanext-hierarchy
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-os
cd ckanext-os
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-qa
cd ckanext-qa
git checkout 2.0
cd -

git clone https://github.com/datagovuk/ckanext-report
cd ckanext-report
git checkout master
cd -

git clone	https://github.com/datagovuk/ckanext-spatial
cd ckanext-spatial
git checkout dgu
cd -

git clone	https://github.com/datagovuk/ckanext-taxonomy
cd ckanext-taxonomy
git checkout master
cd -

git clone	https://github.com/okfn/ckanext-importlib
cd ckanext-importlib
git checkout master
cd -

git clone	https://github.com/datagovuk/shared_dguk_assets
cd shared_dguk_assets
git checkout master
cd -

git clone   https://github.com/datagovuk/logreporter
cd logreporter
git checkout master
cd -

git clone   https://github.com/datagovuk/dgu_d7
cd dgu_d7
git checkout master
cd -

