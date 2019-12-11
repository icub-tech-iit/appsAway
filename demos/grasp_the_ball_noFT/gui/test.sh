#!/bin/bash

echo " "
echo " "
echo " "
echo " "
echo "Running from script"
echo "Hello icub-tech Application"

p=7; 
  
for((m=1; m<=p; m++)) 
do
    # This loop print spaces 
    # required 
    for((a=i; a<=p; a++)) 
    do
      echo -ne " "; 
    done
      
    # This loop print the left 
    # side of the pyramid 
    for((n=1; n<=m; n++)) 
    do
      echo -ne "#"; 
    done
  
    # This loop print right  
    # side of the pryamid. 
    for((i=1; i<m; i++)) 
    do
      echo -ne "#"; 
    done
  
    # New line 
    echo; 
done


echo " "
echo " "
echo " "
echo " "