package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.FairnessRequest;
import com.skillswap.backend.backend.dto.FairnessResponse;
import com.skillswap.backend.backend.service.FairnessService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FairnessController {

    private final FairnessService fairnessService;

    public FairnessController(FairnessService fairnessService) {
        this.fairnessService = fairnessService;
    }

    @PostMapping("/fairness")
    public FairnessResponse evaluate(@RequestBody FairnessRequest request) {
        String left = request == null ? "" : request.getLeftTaskText();
        String right = request == null ? "" : request.getRightTaskText();
        return fairnessService.evaluate(left, right);
    }
}
