#/usr/bin/env bash

# git clone steps
# ---------------

git clone	git@github.com:datagovuk/ckan
cd ckan
git checkout release-v2.2-dgu
git remote add okfn git@github.com:okfn/ckan
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
ln -s ../commit-msg.githook ./.git/hooks/commit-msg
cd -

git clone	git@github.com:datagovuk/ckanext-ga-report
cd ckanext-ga-report
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-harvest
cd ckanext-harvest
git checkout 2.0
cd -

git clone	git@github.com:datagovuk/ckanext-os
cd ckanext-os
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-qa
cd ckanext-qa
git checkout 2.0
cd -

git clone	git@github.com:datagovuk/ckanext-spatial
cd ckanext-spatial
git checkout dgu
cd -

git clone	git@github.com:okfn/ckanext-importlib
cd ckanext-importlib
git checkout master
cd -

git clone	git@github.com:datagovuk/ckanext-hierarchy
cd ckanext-hierarchy
git checkout master
cd -

git clone	git@github.com:datagovuk/shared_dguk_assets
cd shared_dguk_assets
git checkout redesign
cd -

git clone   git@github.com:datagovuk/logreporter.git
cd logreporter
git checkout master
cd -

