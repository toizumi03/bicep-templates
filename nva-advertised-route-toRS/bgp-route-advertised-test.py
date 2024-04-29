import ipaddress
import subprocess

def generate_ip_addresses(num):
    base_ip = ipaddress.IPv4Address('0.0.0.0')
    with open('/tmp/frr.conf', 'w') as frr_file:
        frr_file.write("router bgp 65010\n")
        frr_file.write("address-family ipv4 unicast\n")
        for i in range(1, num + 1):
            ip = base_ip + i
            frr_file.write("network {ip}/32\n")
            print(ip, end='')
            print('/32')
        frr_file.write(content1)            
        print("指定した経路数から Dummy Route を作成し、Config に投入しました")
        print (frr_file)

content1 = '''
    neighbor 10.0.3.4 remote-as 65515
    neighbor 10.0.3.4 ebgp-multihop 255
    neighbor 10.0.3.5 remote-as 65515
    neighbor 10.0.3.5 ebgp-multihop 255
    !
    address-family ipv4 unicast
        neighbor 10.0.3.4 soft-reconfiguration inbound
        neighbor 10.0.3.4 route-map rmap-bogon-asns in
        neighbor 10.0.3.4 route-map rmap-azure-asns out
        neighbor 10.0.3.5 soft-reconfiguration inbound
        neighbor 10.0.3.5 route-map rmap-bogon-asns in
        neighbor 10.0.3.5 route-map rmap-azure-asns out
    exit-address-family
    exit
    !
    bgp as-path access-list azure-asns seq 5 permit _65515_
    bgp as-path access-list bogon-asns seq 5 permit _0_
    bgp as-path access-list bogon-asns seq 10 permit _23456_
    bgp as-path access-list bogon-asns seq 15 permit _1310[0-6][0-9]_|_13107[0-1]_
    bgp as-path access-list bogon-asns seq 20 deny _65515_
    bgp as-path access-list bogon-asns seq 25 permit ^65
    !
    route-map rmap-bogon-asns deny 5
    match as-path bogon-asns
    exit
    !
    route-map rmap-bogon-asns permit 10
    exit
    !
    route-map rmap-azure-asns deny 5
    match as-path azure-asns
    exit
    !
    route-map rmap-azure-asns permit 10
    exit
    !
'''

# コマンドをリスト形式で指定
command1 = ['cp', '/tmp/frr.conf', '/etc/frr/frr.conf']
command2 = ['systemctl', 'restart', 'frr']

# コマンドを実行
subprocess.run(command1)
subprocess.run(command2)

try:
    user_input = int(input("広報したい経路数を入力してください: "))
    generate_ip_addresses(user_input)

except ValueError:
    print("無効な入力です。整数を入力してください。")
