//vtikha
//
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>47</ins><ul><li>city: <del>V</del><b>Geno</b>a<del>l</del><b>, Metro</b>p<b>olit</b>a<del>r</del><b>n City of Geno</b>a<del>íso</del>, <del>Chi</del><b>Ita</b>l<del>e</del><b>y</b></li><li>lat: <del>-33</del><b>44</b>.<b>4</b>0<b>56</b>4<del>7238</del><b>99</b></li><li>long: <del>-71</del><b>8</b>.<b>94</b>6<del>1</del>2<b>5</b>6<del>8849999999</del></li></ul></li></ul>
db.robots.update ({id: 47},{$set: { city: "Genoa, Metropolitan City of Genoa, Italy", lat: "44.4056499", long: "8.946256"}});
