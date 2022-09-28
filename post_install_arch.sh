# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    post_install_arch.sh                               :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/09/27 01:28:29 by pharbst           #+#    #+#              #
#    Updated: 2022/09/27 01:32:22 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

USER=peter


su -
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syyu
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R $USER:users ./yay
exit
cd /opt/yay
makepkg -si
sudo pacman -S 