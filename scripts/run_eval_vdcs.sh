#!/usr/bin/env bash
# Evaluate the clean DreamerV3 policy on VDCS Markov-temporal corruptions
# with the frozen ACO-MoE adapter inserted before the world-model encoder.
#
# Reuse the clean logdir so that the policy weights load via latest.pt.
# `--steps` is small (just enough to trigger the eval loop) and
# `--prefill 0` skips random data collection.
set -euo pipefail
cd "$(dirname "$0")/.."

TASK="${TASK:-dmc_walker_walk}"
CLEAN_LOGDIR="${CLEAN_LOGDIR:-logdir/clean/${TASK}}"
EVAL_LOGDIR="${EVAL_LOGDIR:-logdir/eval_vdcs/${TASK}}"
ADAPTER_CKPT="${ADAPTER_CKPT:-checkpoints/aco_moe/moe_unet_best.pth}"
EVAL_EPISODES="${EVAL_EPISODES:-10}"

mkdir -p "${EVAL_LOGDIR}"
if [[ -f "${CLEAN_LOGDIR}/latest.pt" && ! -f "${EVAL_LOGDIR}/latest.pt" ]]; then
    cp "${CLEAN_LOGDIR}/latest.pt" "${EVAL_LOGDIR}/latest.pt"
fi
if [[ -d "${CLEAN_LOGDIR}/train_eps" && ! -d "${EVAL_LOGDIR}/train_eps" ]]; then
    cp -r "${CLEAN_LOGDIR}/train_eps" "${EVAL_LOGDIR}/train_eps"
fi

MUJOCO_GL="${MUJOCO_GL:-egl}" python dreamer.py \
    --configs dmc_vision adapt_vdcs_markov_temporal \
    --task "${TASK}" \
    --logdir "${EVAL_LOGDIR}" \
    --dual_stream_unet_checkpoint "${ADAPTER_CKPT}" \
    --steps 0 \
    --prefill 0 \
    --eval_every 1 \
    --eval_episode_num "${EVAL_EPISODES}" \
    "$@"
