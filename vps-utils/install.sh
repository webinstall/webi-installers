{
    rm -f "$HOME/.local/bin/vps-myip" "$HOME/.local/bin/vps-addswap" "$HOME/.local/bin/cap-net-bind"
    #webi_download "$WEBI_HOST/packages/vps-utils/" "$HOME/.local/bin/"
    webi_download "$WEBI_HOST/packages/vps-utils/cap-net-bind.sh" "$HOME/.local/bin/cap-net-bind"
    webi_download "$WEBI_HOST/packages/vps-utils/vps-myip.sh" "$HOME/.local/bin/vps-myip"
    webi_download "$WEBI_HOST/packages/vps-utils/myip.sh" "$HOME/.local/bin/myip"
    webi_download "$WEBI_HOST/packages/vps-utils/vps-addswap.sh" "$HOME/.local/bin/vps-addswap"
    chmod a+x "$HOME/.local/bin/cap-net-bind"
    chmod a+x "$HOME/.local/bin/myip"
    chmod a+x "$HOME/.local/bin/vps-"*
}
