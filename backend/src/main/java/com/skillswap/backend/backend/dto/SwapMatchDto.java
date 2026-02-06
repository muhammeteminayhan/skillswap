package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class SwapMatchDto {
    private Long matchId;
    private String status;
    private Long otherUserId;
    private String otherName;
    private String myWanted;
    private String myOffered;
    private String otherWanted;
    private String otherOffered;
    private Boolean acceptedByMe;
    private Boolean acceptedByOther;
    private Boolean doneByMe;
    private Boolean doneByOther;
    private Boolean canReview;
    private Integer myCredit;
    private Integer otherCredit;
    private Integer creditDiff;
    private Integer fairnessPercent;
    private Boolean creditRequiredByMe;
    private Integer requiredCredits;
    private Integer pricePerCredit;
    private Double platformFeeRate;
    private Integer requiredAmountTl;
    private Integer platformFeeAmountTl;
    private Integer payoutAmountTl;
}
