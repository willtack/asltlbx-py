# emacs: -*- mode: python; py-indent-offset: 4; indent-tabs-mode: nil -*-
# vi: set ft=python sts=4 ts=4 sw=4 et:
"""ReportCapableInterfaces for masks tools."""
import os
import numpy as np
import nibabel as nb
from nilearn.masking import compute_epi_mask
import scipy.ndimage as nd

from nipype.interfaces import fsl, ants
from nipype.interfaces.base import (
    File,
    BaseInterfaceInputSpec,
    traits,
    isdefined,
    InputMultiPath,
    Str,
)
from nipype.interfaces.mixins import reporting
from nipype.algorithms import confounds
from seaborn import color_palette
#from .. import NIWORKFLOWS_LOG
#from . import report_base as nrc
import workflows.report_base as nrc

import logging

NIWORKFLOWS_LOG = logging.getLogger("asltlbx")
NIWORKFLOWS_LOG.setLevel(logging.INFO)


class _BETInputSpecRPT(nrc._SVGReportCapableInputSpec, fsl.preprocess.BETInputSpec):
    pass


class _BETOutputSpecRPT(
    reporting.ReportCapableOutputSpec, fsl.preprocess.BETOutputSpec
):
    pass


class BETRPT(nrc.SegmentationRC, fsl.BET):
    input_spec = _BETInputSpecRPT
    output_spec = _BETOutputSpecRPT

    def _run_interface(self, runtime):
        if self.generate_report:
            self.inputs.mask = True

        return super(BETRPT, self)._run_interface(runtime)

    def _post_run_hook(self, runtime):
        """ generates a report showing slices from each axis of an arbitrary
        volume of in_file, with the resulting binary brain mask overlaid """

        self._anat_file = self.inputs.in_file
        self._mask_file = self.aggregate_outputs(runtime=runtime).mask_file
        self._seg_files = [self._mask_file]
        self._masked = self.inputs.mask

        NIWORKFLOWS_LOG.info(
            'Generating report for BET. file "%s", and mask file "%s"',
            self._anat_file,
            self._mask_file,
        )

        return super(BETRPT, self)._post_run_hook(runtime)


class _BrainExtractionInputSpecRPT(
    nrc._SVGReportCapableInputSpec, ants.segmentation.BrainExtractionInputSpec
):
    pass


class _BrainExtractionOutputSpecRPT(
    reporting.ReportCapableOutputSpec, ants.segmentation.BrainExtractionOutputSpec
):
    pass


class BrainExtractionRPT(nrc.SegmentationRC, ants.segmentation.BrainExtraction):
    input_spec = _BrainExtractionInputSpecRPT
    output_spec = _BrainExtractionOutputSpecRPT

    def _post_run_hook(self, runtime):
        """ generates a report showing slices from each axis """

        brain_extraction_mask = self.aggregate_outputs(
            runtime=runtime
        ).BrainExtractionMask

        if (
            isdefined(self.inputs.keep_temporary_files)
            and self.inputs.keep_temporary_files == 1
        ):
            self._anat_file = self.aggregate_outputs(runtime=runtime).N4Corrected0
        else:
            self._anat_file = self.inputs.anatomical_image
        self._mask_file = brain_extraction_mask
        self._seg_files = [brain_extraction_mask]
        self._masked = False

        NIWORKFLOWS_LOG.info(
            'Generating report for ANTS BrainExtraction. file "%s", mask "%s"',
            self._anat_file,
            self._mask_file,
        )

        return super(BrainExtractionRPT, self)._post_run_hook(runtime)


# TODO: move this interface to nipype.interfaces.nilearn
class _ComputeEPIMaskInputSpec(nrc._SVGReportCapableInputSpec, BaseInterfaceInputSpec):
    in_file = File(exists=True, desc="3D or 4D EPI file")
    dilation = traits.Int(desc="binary dilation on the nilearn output")


class _ComputeEPIMaskOutputSpec(reporting.ReportCapableOutputSpec):
    mask_file = File(exists=True, desc="Binary brain mask")


class ComputeEPIMask(nrc.SegmentationRC):
    input_spec = _ComputeEPIMaskInputSpec
    output_spec = _ComputeEPIMaskOutputSpec

    def _run_interface(self, runtime):
        orig_file_nii = nb.load(self.inputs.in_file)
        in_file_data = orig_file_nii.get_fdata()

        # pad the data to avoid the mask estimation running into edge effects
        in_file_data_padded = np.pad(
            in_file_data, (1, 1), "constant", constant_values=(0, 0)
        )

        padded_nii = nb.Nifti1Image(
            in_file_data_padded, orig_file_nii.affine, orig_file_nii.header
        )

        mask_nii = compute_epi_mask(padded_nii, exclude_zeros=True)

        mask_data = np.asanyarray(mask_nii.dataobj).astype(np.uint8)
        if isdefined(self.inputs.dilation):
            mask_data = nd.morphology.binary_dilation(mask_data).astype(np.uint8)

        # reverse image padding
        mask_data = mask_data[1:-1, 1:-1, 1:-1]

        # exclude zero and NaN voxels
        mask_data[in_file_data == 0] = 0
        mask_data[np.isnan(in_file_data)] = 0

        better_mask = nb.Nifti1Image(
            mask_data, orig_file_nii.affine, orig_file_nii.header
        )
        better_mask.set_data_dtype(np.uint8)
        better_mask.to_filename("mask_file.nii.gz")

        self._mask_file = os.path.join(runtime.cwd, "mask_file.nii.gz")

        runtime.returncode = 0
        return super(ComputeEPIMask, self)._run_interface(runtime)

    def _list_outputs(self):
        outputs = super(ComputeEPIMask, self)._list_outputs()
        outputs["mask_file"] = self._mask_file
        return outputs

    def _post_run_hook(self, runtime):
        """ generates a report showing slices from each axis of an arbitrary
        volume of in_file, with the resulting binary brain mask overlaid """

        self._anat_file = self.inputs.in_file
        self._mask_file = self.aggregate_outputs(runtime=runtime).mask_file
        self._seg_files = [self._mask_file]
        self._masked = True

        NIWORKFLOWS_LOG.info(
            'Generating report for nilearn.compute_epi_mask. file "%s", and mask file "%s"',
            self._anat_file,
            self._mask_file,
        )

        return super(ComputeEPIMask, self)._post_run_hook(runtime)


class _ACompCorInputSpecRPT(nrc._SVGReportCapableInputSpec, confounds.CompCorInputSpec):
    pass


class _ACompCorOutputSpecRPT(
    reporting.ReportCapableOutputSpec, confounds.CompCorOutputSpec
):
    pass


class ACompCorRPT(nrc.SegmentationRC, confounds.ACompCor):
    input_spec = _ACompCorInputSpecRPT
    output_spec = _ACompCorOutputSpecRPT

    def _post_run_hook(self, runtime):
        """ generates a report showing slices from each axis """

        if len(self.inputs.mask_files) != 1:
            raise ValueError(
                "ACompCorRPT only supports a single input mask. "
                "A list %s was found." % self.inputs.mask_files
            )
        self._anat_file = self.inputs.realigned_file
        self._mask_file = self.inputs.mask_files[0]
        self._seg_files = self.inputs.mask_files
        self._masked = False

        NIWORKFLOWS_LOG.info(
            'Generating report for aCompCor. file "%s", mask "%s"',
            self.inputs.realigned_file,
            self._mask_file,
        )

        return super(ACompCorRPT, self)._post_run_hook(runtime)


class _TCompCorInputSpecRPT(
    nrc._SVGReportCapableInputSpec, confounds.TCompCorInputSpec
):
    pass


class _TCompCorOutputSpecRPT(
    reporting.ReportCapableOutputSpec, confounds.TCompCorOutputSpec
):
    pass


class TCompCorRPT(nrc.SegmentationRC, confounds.TCompCor):
    input_spec = _TCompCorInputSpecRPT
    output_spec = _TCompCorOutputSpecRPT

    def _post_run_hook(self, runtime):
        """ generates a report showing slices from each axis """

        high_variance_masks = self.aggregate_outputs(
            runtime=runtime
        ).high_variance_masks

        if isinstance(high_variance_masks, list):
            raise ValueError(
                "TCompCorRPT only supports a single output high variance mask. "
                "A list %s was found." % high_variance_masks
            )
        self._anat_file = self.inputs.realigned_file
        self._mask_file = high_variance_masks
        self._seg_files = [high_variance_masks]
        self._masked = False

        NIWORKFLOWS_LOG.info(
            'Generating report for tCompCor. file "%s", mask "%s"',
            self.inputs.realigned_file,
            self.aggregate_outputs(runtime=runtime).high_variance_masks,
        )

        return super(TCompCorRPT, self)._post_run_hook(runtime)


class _SimpleShowMaskInputSpec(nrc._SVGReportCapableInputSpec):
    background_file = File(exists=True, mandatory=True, desc="file before")
    mask_file = File(exists=True, mandatory=True, desc="file before")


class SimpleShowMaskRPT(nrc.SegmentationRC, nrc.ReportingInterface):
    input_spec = _SimpleShowMaskInputSpec

    def _post_run_hook(self, runtime):
        self._anat_file = self.inputs.background_file
        self._mask_file = self.inputs.mask_file
        self._seg_files = [self.inputs.mask_file]
        self._masked = True

        return super(SimpleShowMaskRPT, self)._post_run_hook(runtime)


class _ROIsPlotInputSpecRPT(nrc._SVGReportCapableInputSpec):
    in_file = File(
        exists=True, mandatory=True, desc="the volume where ROIs are defined"
    )
    in_rois = InputMultiPath(
        File(exists=True), mandatory=True, desc="a list of regions to be plotted"
    )
    in_mask = File(exists=True, desc="a special region, eg. the brain mask")
    masked = traits.Bool(False, usedefault=True, desc="mask in_file prior plotting")
    colors = traits.Either(
        None, traits.List(Str), usedefault=True, desc="use specific colors for contours"
    )
    levels = traits.Either(
        None,
        traits.List(traits.Float),
        usedefault=True,
        desc="pass levels to nilearn.plotting",
    )
    mask_color = Str("r", usedefault=True, desc="color for mask")



