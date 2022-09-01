rm -rf dist &&
yarn build &&
cd dist &&
git init &&
git add . &&
git commit -m "update" &&
git branch -M gh-pages &&
git remote add origin git@github.com:wlin00/vue-plum-wlin.git &&
git push -f -u origin gh-pages &&
cd -
