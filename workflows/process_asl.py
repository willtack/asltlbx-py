import pandas as pd
import nibabel as nb
import numpy as np
from nibabel.processing import smooth_image
from nipype.utils.filemanip import fname_presuffix
import os


def readjson(jsonfile):
    import json
    with open(jsonfile) as f:
        data = json.load(f)
    return data


def regmotoasl(asl, m0file, m02asl):
    from nipype.interfaces import fsl
    meanasl = fsl.MeanImage(); meanasl.inputs.in_file = asl
    meanasl.inputs.out_file = fname_presuffix(asl, suffix='_meanasl') + ".gz"
    meanasl.run()
    meanm0 = fsl.MeanImage(); meanm0.inputs.in_file = m0file
    meanm0.inputs.out_file = fname_presuffix(asl, suffix='_meanm0') + ".gz"
    meanm0.run()
    flt = fsl.FLIRT(bins=640, cost_func='mutualinfo')
    flt.inputs.in_file = meanm0.inputs.out_file
    flt.inputs.reference = meanasl.inputs.out_file
    flt.inputs.out_file = m02asl
    flt.run()
    return m02asl


class LabelingEfficiencyNotFound(Exception):
    """LabelingEfficiency was not specified and no value could be derived."""


def extract_cbf(asl, m0, aslcontext, m0type, fwhm, mask, outputdir):
    """

    :param mask: ASL brain mask
    :param outputdir:
    :param fwhm: smoothing kernel for M0
    :param m0type:
    :param aslcontext:
    :param asl: Path to ASL file
    :param m0:  Path to M0 file
    :return:
    """

    # os.mkdir(os.path.join(outputdir, 'asl'))

    m0file = []
    aslfile_linkedM0 = []
    mask = nb.load(mask).get_fdata()
    aslcontext1 = os.path.abspath(aslcontext)
    idasl = pd.read_csv(aslcontext1)['volume_type'].tolist()

    # read the data
    allasl = nb.load(asl)
    dataasl = allasl.get_fdata()

    # get the control,tag,moscan or label
    controllist = [i for i in range(0, len(idasl)) if idasl[i] == 'control']
    labellist = [i for i in range(0, len(idasl)) if idasl[i] == 'label']
    m0list = [i for i in range(0, len(idasl)) if idasl[i] == 'm0scan']
    #deltamlist = [i for i in range(0, len(idasl)) if idasl[i] == 'deltam']
    cbflist = [i for i in range(0, len(idasl)) if idasl[i] == 'CBF']

    # extract m0 file and register it to ASL if separate
    if m0type == "Separate":
        #m0file_metadata = readjson(m0file.replace('nii.gz', 'json'))
        #aslfile_linkedM0 = os.path.abspath(asl)

        newm0 = fname_presuffix(asl, suffix='_m0file') + ".gz"  #
        newm0 = regmotoasl(asl=asl, m0file=m0, m02asl=newm0)
        m0data_smooth = smooth_image(nb.load(newm0), fwhm=fwhm).get_data()
        if len(m0data_smooth.shape) > 3:
            m0dataf = mask * np.mean(m0data_smooth, axis=3)
        else:
            m0dataf = mask * m0data_smooth

    elif m0type == "Included":
        modata2 = dataasl[:, :, :, m0list]
        con2 = nb.Nifti1Image(modata2, allasl.affine, allasl.header)
        m0data_smooth = smooth_image(con2, fwhm=fwhm).get_data()
        if len(m0data_smooth.shape) > 3:
            m0dataf = mask * np.mean(m0data_smooth, axis=3)
        else:
            m0dataf = mask * m0data_smooth

    elif m0type == "Absent":
        if len(controllist) > 0:
            control_img = dataasl[:, :, :, controllist]
            con = nb.Nifti1Image(control_img, allasl.affine, allasl.header)
            control_img1 = smooth_image(con, fwhm=fwhm).get_data()
            m0dataf = mask * np.mean(control_img1, axis=3)
        elif len(cbflist) > 0:
            m0dataf = mask
        else:
            raise RuntimeError("m0scan is absent")
    else:
        raise RuntimeError("no pathway to m0scan")

    if len(dataasl.shape) == 5:
        raise RuntimeError('Input image (%s) is 5D.')
    # if len(deltamlist) > 0:
    #     cbf_data = dataasl[:, :, :, deltamlist]
    if len(cbflist) > 0:
        cbf_data = dataasl[:, :, :, cbflist]
    elif len(labellist) > 0:
        control_img = dataasl[:, :, :, controllist]
        label_img = dataasl[:, :, :, labellist]
        cbf_data = np.subtract(control_img, label_img) # do the label-control subtraction
    else:
        raise RuntimeError('no valid asl or cbf image.')

    out_file = fname_presuffix(asl, suffix='_cbftimeseries')
    print(f"out_file {out_file}")
    out_avg = fname_presuffix(asl, suffix='_m0file')
    nb.Nifti1Image(
        cbf_data, allasl.affine, allasl.header).to_filename(out_file)
    nb.Nifti1Image(
        m0dataf, allasl.affine, allasl.header).to_filename(out_avg)

    out_file = os.path.abspath(out_file)
    out_avg = os.path.abspath(out_avg)

    return out_file, out_avg, allasl.affine


def cbfcomputation(pld, ld, m0scale, mask, m0file, cbffile, labelefficiency):

    """
    compute cbf with pld and multi pld
    metadata
      cbf metadata
    mask
      asl mask in native space
    m0file
      m0scan
    cbffile
      already processed cbf after tag-control subtraction
    m0scale
      relative scale between m0scan and asl, default is 1
    """
    labeltype = 'pCASL'  # make adjustable later
    tau = float(ld)
    plds = float(pld)  # must be single PLD (for now)
    # m0scale = metadata['M0']
    magstrength = 3  # 3T -- make adjustable later
    t1blood = (110 * int(magstrength) + 1316) / 1000  # https://onlinelibrary.wiley.com/doi/pdf/10.1002/mrm.24550
    #print(mask)
    maskx = nb.load(mask).get_fdata()
    #print("T1 of blood: " + str(t1blood))
    if labelefficiency is not None:
        labeleff = float(labelefficiency)
    elif 'CASL' in labeltype:
        labeleff = 0.72
    elif 'PASL' in labeltype:
        labeleff = 0.8
    else:
        raise LabelingEfficiencyNotFound('No labeling efficiency')
    part_coeff = 0.9  # brain partition coefficient

    if 'CASL' in labeltype:
        pf1 = (6000.0 * part_coeff) / (2.0 * labeleff * t1blood * (1.0 - np.exp(-(tau / t1blood))))
        perfusion_factor = pf1 * np.exp(plds / t1blood)
    elif 'PASL' in labeltype:
        inverstiontime = plds  # As per BIDS: inversiontime for PASL == PostLabelingDelay
        pf1 = (6000 * part_coeff) / (2 * labeleff)
        perfusion_factor = (pf1 * np.exp(inverstiontime / t1blood)) / inverstiontime
    # perfusion_factor = np.array(perfusion_factor)
    # print(perfusion_factor)
    #maskx = nb.load(mask).get_fdata()
    m0data = nb.load(m0file).get_fdata()
    m0data = m0data[maskx == 1]
    # compute cbf
    cbf_data = nb.load(cbffile).get_fdata()
    cbf_data = cbf_data[maskx == 1]
    cbf1 = np.zeros(cbf_data.shape)
    m0scale = float(m0scale)
    if len(cbf_data.shape) < 2:
        cbf1 = np.divide(cbf_data, (m0scale * m0data))
    else:
        for i in range(cbf1.shape[1]):
            cbf1[:, i] = np.divide(cbf_data[:, i], (m0scale * m0data))
        # m1=m0scale*m0_data
        # cbf1=np.divide(cbf_data,m1)
        # for compute cbf for each PLD and TI
    # att = None
    if hasattr(perfusion_factor, '__len__') and cbf_data.shape[1] > 1:
        permfactor = np.tile(perfusion_factor, int(cbf_data.shape[1] / len(perfusion_factor)))
        cbf_data_ts = np.zeros(cbf_data.shape)

        # calculate  cbf with multiple plds
        # for i in range(cbf_data.shape[1]):
        #     cbf_data_ts[:, i] = np.multiply(cbf1[:, i], permfactor[i])
        # cbf = np.zeros([cbf_data_ts.shape[0], int(cbf_data.shape[1] / len(perfusion_factor))])
        # cbf_xx = np.split(cbf_data_ts, int(cbf_data_ts.shape[1] / len(perfusion_factor)), axis=1)

        # calculate weighted cbf with multiplds
        # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3791289/
        # https://pubmed.ncbi.nlm.nih.gov/22084006/
        # for k in range(len(cbf_xx)):
        #     cbf_plds = cbf_xx[k]
        #     pldx = np.zeros([cbf_plds.shape[0], len(cbf_plds)])
        #     for j in range(cbf_plds.shape[1]):
        #         pldx[:, j] = np.array(np.multiply(cbf_plds[:, j], plds[j]))
        #     cbf[:, k] = np.divide(np.sum(pldx, axis=1), np.sum(plds))

    elif hasattr(perfusion_factor, '__len__') and len(cbf_data.shape) < 2:
        cbf_ts = np.zeros(cbf_data.shape, len(perfusion_factor))
        for i in len(perfusion_factor):
            cbf_ts[:, i] = np.multiply(cbf1, perfusion_factor[i])
        cbf = np.divide(np.sum(cbf_ts, axis=1), np.sum(perfusion_factor))
    else:
        cbf = cbf1 * np.array(perfusion_factor)
        # cbf is timeseries
    # return cbf to nifti shape
    if len(cbf.shape) < 2:
        tcbf = np.zeros(maskx.shape)
        tcbf[maskx == 1] = cbf
    else:
        tcbf = np.zeros([maskx.shape[0], maskx.shape[1], maskx.shape[2], cbf.shape[1]])
        for i in range(cbf.shape[1]):
            tcbfx = np.zeros(maskx.shape)
            tcbfx[maskx == 1] = cbf[:, i]
            tcbf[:, :, :, i] = tcbfx
    if len(tcbf.shape) < 4:
        meancbf = tcbf
    else:
        meancbf = np.nanmean(tcbf, axis=3)

    meancbf = np.nan_to_num(meancbf)
    tcbf = np.nan_to_num(tcbf)
    #att = np.nan_to_num(att)

    return meancbf, tcbf
