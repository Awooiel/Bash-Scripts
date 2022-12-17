installSoftware() {
    while true; do
        read -p "Is this a fresh install? (y) or an update (n) " yn
        case $yn in
        [Yy]*)
            echo "Running System Installation"
            sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
            sudo apt update && sudo apt upgrade -y
            sudo apt-get install -y apt-transport-https ca-certificates curl ca-certificates curl gnupg lsb-release
            sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
            echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
            sudo apt-get update
            sudo apt-get remove -y docker docker-engine docker.io containerd runc
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
            sudo apt-get update
            sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
            sudo swapoff -a
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin kubelet kubeadm kubectl
            sudo apt-mark hold kubelet kubeadm kubectl
            sudo apt autoremove -y
            break
            ;;
        [Nn]*)
            echo "Running System Updates"
            sudo apt update && sudo apt upgrade -y
            sudo apt autoremove -y
            echo "Done Updating"
            exit
            break
            ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
    echo "Done Running install/update system"
}

resetK8() {
    sudo kubeadm reset
    rm -R $HOME/.kube/
    sudo apt-get remove -y --allow-change-held-packages docker-ce docker-ce-cli containerd.io docker-compose-plugin kubelet kubeadm kubectl
    sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
    sudo apt autoremove -y
    sudo rm -R /etc/kubernetes
}

setupKubernetes() {
    echo "Setting up service configuration"
    while true; do
        read -p "Is this a master? (y) or a node (n) " yn
        case $yn in
        [Yy]*)
            echo 'Enviroment="cgroup-driver=systemd/cgroup-driver=cgroupfs"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
            sudo rm /etc/containerd/config.toml
            sudo rm /etc/docker/daemon.json
            echo "{" | sudo tee -a '/etc/docker/daemon.json'
            echo '    "exec-opts": ["native.cgroupdriver=systemd"]' | sudo tee -a '/etc/docker/daemon.json'
            echo "}" | sudo tee -a '/etc/docker/daemon.json'
            sudo systemctl daemon-reload
            sudo systemctl restart docker
            sudo systemctl restart kubelet
            sudo systemctl restart containerd
            while true; do
                read -p "Set up on physical network (y) Set up using Tailscale (n) " yn
                case $yn in
                [Yy]*)
                    sudo kubeadm init --pod-network-cidr=192.168.0.0/16
                    break
                    ;;
                [Nn]*)
                    curl -fsSL https://tailscale.com/install.sh | sh
                    echo "Please Sign into Tailscale to connect to the network"
                    sudo tailscale up
                    sleep 5
                    for ip in $(tailscale ip -4); do sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$ip; done
                    break
                    ;;
                *) echo "Please answer yes or no." ;;
                esac
            done
            mkdir -p $HOME/.kube
            sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
            sudo chown $(id -u):$(id -g) $HOME/.kube/config
            echo "Installing Kubernetes Calico Networking"
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml
            kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
            echo "Checking for cluster nodes, this should show some"
            kubectl get nodes -o wide
            sleep 5
            echo "Installing Kubernetes WebUI Dashboard"
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml
            for ip in $(tailscale ip -4); do kubectl proxy --address='$ip'; done
            break
            ;;
        [Nn]*)

            break
            ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
}

init() {
    echo "Initializing"
    installSoftware
    setupKubernetes
}
init
