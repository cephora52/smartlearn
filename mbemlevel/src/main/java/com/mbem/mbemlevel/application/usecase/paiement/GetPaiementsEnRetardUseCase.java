package com.mbem.mbemlevel.application.usecase.paiement;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
/** Retourne toutes les tranches dont l'échéance est dépassée. */
@Service @RequiredArgsConstructor
public class GetPaiementsEnRetardUseCase {
    private final PaiementRepository repo;
    @Transactional(readOnly=true)
    public List<Tranche> executer() { return repo.findTranchesEnRetard(); }
}
