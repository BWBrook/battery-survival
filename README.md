# battery-survival
Survival analysis of camera trap battery life. Cameras are located around Tasmania.

### Setup Instructions for RStudio on a CPU Instance

#### 1. Create a CPU Instance
- Refer to the repository [mewc-infrastructure](https://github.com/zaandahl/mewc-infrastructure) for guidance on creating a CPU instance suitable for RStudio.

#### 2. SSH to the Instance and Setup SSH Keys
- SSH into your instance using your personal public key. Replace `your_personal_public_key_path` and `your_instance_ip` with your specific details.
  ```bash
  scp -i your_personal_public_key_path ~/.ssh/id_ed25519.pub user@your_instance_ip:~/.ssh/authorized_keys
  ```
- Then SSH into your instance using your personal key:
  ```bash
  ssh -i ~/.ssh/id_ed25519 user@your_instance_ip
  ```

#### 3. Clone the Development Repository
- On your Nectar instance, clone the development repository:
  ```bash
  git clone git@github.com:zaandahl/battery-survival.git
  ```
- Navigate into the cloned directory:
  ```bash
  cd battery-survival
  ```

#### 4. Build and Run the Docker Container
- Build the Docker container:
  ```bash
  sudo docker compose build
  ```
- Start the Docker container:
  ```bash
  sudo docker compose up -d
  ```

#### 5. Connect to RStudio
- Access RStudio by connecting to `http://your_instance_ip:8787`.

#### 6. Lock `rstanarm` to a Specific Commit
- Within an R session, lock `rstanarm` to a specific commit (TODO cook this into the Docker setup for the repo):
  ```R
  pacman::p_install_gh("stan-dev/rstanarm@f9047a095f00a2f3d1d0420059dcf52842ad3c42")
  ```

#### 7. Transfer Data from Local Machine
- Copy your dataset from your local machine to the instance. Replace `your_data_directory_path` and `your_instance_ip` with your details.
  ```bash
  scp -r -i your_personal_public_key_path your_data_directory_path/* user@your_instance_ip:battery-survival/data
  ```
- Similarly, copy any results from your local machine:
  ```bash
  scp -r -i your_personal_public_key_path your_results_directory_path/* user@your_instance_ip:battery-survival/results
  ```

