# reproducer-RHEL46814
Things needed to reproduce the [SR-IOV](https://youtu.be/hRHsk8Nycdg?si=4u84UcpA2alBmdU0) issue
- Bare metal system with [Intel E810](https://www.intel.com/content/www/us/en/products/details/ethernet/800-network-adapters/e810-network-adapters/products.html):
  - [OCP 4.16.0+](https://docs.openshift.com/container-platform/4.16/installing/installing_on_prem_assisted/installing-on-prem-assisted.html)
  - At least one [**tagged** VLAN](https://en.wikipedia.org/wiki/IEEE_802.1Q) to which test pod(s) can be attachted to 
    - a destination on the tagged VLAN that can be pinged (e.g. a gateway or another server that has an IP on the same tagged VLAN)
  - [RH SR-IOV Operator](https://docs.openshift.com/container-platform/4.16/networking/hardware_networks/installing-sriov-operator.html) installed 
- Configuration as follows:
  - [SR-IOV Operator Config](https://docs.openshift.com/container-platform/4.16/networking/hardware_networks/configuring-sriov-operator.html#configure-sr-iov-operator-single-node_configuring-sriov-operator) 
   ```
    oc get -o yaml sriovoperatorconfig -n openshift-sriov-network-operator
    apiVersion: v1
    items:
    - apiVersion: sriovnetwork.openshift.io/v1
      kind: SriovOperatorConfig
      metadata:
      name: default
      namespace: openshift-sriov-network-operator
    spec:
      disableDrain: true
      enableInjector: false
      enableOperatorWebhook: false
      logLevel: 2
    kind: List
    metadata:
      resourceVersion: ""
   ```
 - **MIND** all the following settings like interface name, VLAN IDs, IPs, ... depend on your setup and will most likely need to be changed
   - create test namespace, [service account (sa)](https://docs.openshift.com/container-platform/4.16/authentication/understanding-and-creating-service-accounts.html) and add [security context constraint (SCC)](https://docs.openshift.com/container-platform/4.16/authentication/managing-security-context-constraints.html) to the created sa, e.g.:
     - `oc new-project sriov-test`
     - `oc create sa priviledged-sa`
     - `oc adm policy add-scc-to-user privileged -z priviledged-sa`
   - create [`SriovNetworkNodePolicy`](https://docs.openshift.com/container-platform/4.16/networking/hardware_networks/configuring-sriov-device.html), e.g. see [here](01-SriovNetworkNodePolicy/sriov-config-netdevice-enp5s0f1.yaml)
   - create [`NetworkAttachmentDefinition`](https://docs.openshift.com/container-platform/4.16/networking/multiple_networks/configuring-additional-network.html#configuring-additional-network_configuration-additional-network-yaml), e.g. see [here](02-nets/vlan/)
     - **MIND** directly configuring `NetworkAttachmentDefinition` for SR-IOV is not the recommended way and instead [`SriovNetwork`](https://docs.openshift.com/container-platform/4.16/networking/hardware_networks/configuring-sriov-net-attach.html) should be used which in turn creates `NetworkAttachmentDefinition` in the defined namespace. **However** for this replicator `NetworkAttachmentDefinition` are created directly omitting `SriovNetwork`.
   - create [`StatefulSet`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) running a pod with a tagged VLAN set up inside the pod, e.g see [here](03-sts/vlan/)
   - run a simple ping test, e.g. `for I in {0..9}; do echo -n po-vlan10${I}-0 : ; oc rsh po-vlan10${I}-0 ping -c3 192.168.10${I}.31 |grep transmi;done`
   - to run this in a loop, check out [run_test_loop_bisec](scripts/run_test_loop_bisec)
- in case you do want or need to build a custom image for testing, see https://github.com/dmoessne/rhcos-layering
