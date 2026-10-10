$ whoami
oleg
$ pwd
/home/oleg/projects
$ ls -la | head -5
total 32
drwxr-xr-x  12 oleg oleg 4096 Oct  8 12:00 .
$ echo "Текущая директория: $(pwd)"
Текущая директория: /home/oleg/projects
$ VAR="test" && echo ${VAR^^}
TEST
$ curl -s https://api.example.com | jq '.items[0].name'
"первый"
$ python3 -c 'print(1 + 1)'
2
$ exit
exit
