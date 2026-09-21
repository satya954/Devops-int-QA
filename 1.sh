for i in {1..10} 
do 
	if (( i%2==0 )); then
		print "even"
	else 
		print $i
	fi
done


read -p "Enter yu:" n
for (( i=0; i<=n; i++ ))
do
	print i
done

i=1
while (( i <=n ))
do
  if (( i%15 == 0 ))
	 echo "multiple by 15" 
  elif (( i%3 == 0 ))
	  echo "by 3"
  else
	  echo "5"
  fi
  (( i++ ))
done


if [[ $i -gt 0 ]];
then
	echo "greater"
