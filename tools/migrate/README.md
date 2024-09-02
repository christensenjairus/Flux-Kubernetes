# Volume Migration Instructions
1. Suspend the `apps` Flux kustomization.
2. Scale down the attached workload to 0 replicas.
2. Apply an overlay that creates a `-new` volume and migrates the data from the old volume to the new volume.
2. Manually delete the job once it's completed.
3. Delete the attached workload and the old PVC (assuming you can bring it back with Flux).
4. Update the Helm Release for the Workload to rebuild it and create a new PVC.
5. Immediately scale down the workload again to 0 replicas.
6. Apply the same Kustomization overlay as before with the old volume and new volume names swapped.
7. Manually delete the job once it's completed.
8. Resume the `apps` Flux kustomization.
8. Scale the attached workload back up.
9. Once you verify that it works, delete the (now unneeded) `-new` volume.