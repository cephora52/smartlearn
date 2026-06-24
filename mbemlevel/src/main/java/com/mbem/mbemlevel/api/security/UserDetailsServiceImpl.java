package com.mbem.mbemlevel.api.security;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;
import java.util.List;
@Service @RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {
    private final UtilisateurRepository repo;
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var u = repo.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé: " + email));
        return User.builder()
            .username(u.getId().toString())
            .password(u.getMotDePasseHache())
            .authorities(List.of(new SimpleGrantedAuthority(u.getRole().toSpringRole())))
            .accountLocked(u.estBloque())
            .build();
    }
}
