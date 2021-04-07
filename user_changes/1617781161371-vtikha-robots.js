//vtikha
//&<h3>Field changed in robot manager</h3><br><ul><li>ID: <ins>45</ins><ul><li>city: <del>und</del><b>Zagr</b>e<del>f</del><b>b, Croat</b>i<del>ned</del><b>a</b></li><li>lat: 45.815<del>399</del><b>0108</b></li><li>long: 15.9<del>6656</del>8<b>1919</b></li></ul></li></ul>
db.robots.update ({id: 45},{$set: { city: "Zagreb, Croatia", lat: "45.8150108", long: "15.981919"}});
