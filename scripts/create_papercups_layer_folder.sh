mkdir papercups_node_layer
cd papercups_node_layer
mkdir nodejs
cd nodejs/
npm init -y
npm i --save @papercups-io/papercups
npm install --save lodash
npm install --save axios
cd ..
zip -r papercups_node_layer.zip .
