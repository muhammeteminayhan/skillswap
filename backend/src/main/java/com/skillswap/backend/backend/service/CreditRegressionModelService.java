package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.CreditRegressionModelEntity;
import com.skillswap.backend.backend.repository.CreditRegressionModelRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class CreditRegressionModelService {

    private final CreditRegressionModelRepository creditRegressionModelRepository;
    private final CreditConfig creditConfig;

    public CreditRegressionModelService(
            CreditRegressionModelRepository creditRegressionModelRepository,
            CreditConfig creditConfig
    ) {
        this.creditRegressionModelRepository = creditRegressionModelRepository;
        this.creditConfig = creditConfig;
    }

    public CreditRegressionModelEntity getActiveModel() {
        return creditRegressionModelRepository.findTopByOrderByTrainedAtDesc()
                .orElseGet(this::defaultModel);
    }

    private CreditRegressionModelEntity defaultModel() {
        CreditRegressionModelEntity model = new CreditRegressionModelEntity();
        model.setIntercept(creditConfig.getRegressionIntercept());
        model.setHours(creditConfig.getRegressionHours());
        model.setDifficulty(creditConfig.getRegressionDifficulty());
        model.setRisk(creditConfig.getRegressionRisk());
        model.setScope(creditConfig.getRegressionScope());
        model.setTrust(creditConfig.getRegressionTrust());
        model.setMinCredit(creditConfig.getRegressionMin());
        model.setMaxCredit(creditConfig.getRegressionMax());
        model.setDatasetName("default");
        model.setTrainedAt(LocalDateTime.now());
        return model;
    }
}
