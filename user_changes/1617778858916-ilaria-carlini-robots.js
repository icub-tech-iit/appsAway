//ilaria-carlini
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>1</ins><ul><li>city: Geno<del>v</del><b>a, Metropolitan City of Geno</b>a, Italy</li><li>lat: 44.4<del>72</del><b>0564</b>9<del>7</del><b>9</b></li><li>long: 8.9<del>02</del>4<del>0</del><b>625</b>6</li></ul></li><li>ID: <ins>31</ins><ul><li>city: <b>Via S. Quirico, 19, 16163 </b>Genova<b> GE</b>, Italy</li><li>lat: 44.4729<del>7</del><b>988</b></li><li>long: 8.902<b>5</b>4<b>64000</b>0<del>6</del><b>0002</b></li></ul></li></ul>
db.robots.update ({id: 1},{$set: { city: "Genoa, Metropolitan City of Genoa, Italy", lat: "44.4056499", long: "8.946256"}});
db.robots.update ({id: 31},{$set: { city: "Via S. Quirico, 19, 16163 Genova GE, Italy", lat: "44.4729988", long: "8.902546400000002"}});
